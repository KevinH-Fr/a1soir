# Mémo — Avis Google et cache Redis

**Objet :** Afficher la note et les avis de la fiche Google de la boutique sans épuiser le quota Google  
**Contexte :** Bloc « Avis clients » (`/fr/la_boutique`, pages SEO avec `reviews`) et note `aggregateRating` du schéma `ClothingStore`  
**Principe :** Un seul appel Google par jour (tâche planifiée), les pages ne font que lire le cache  
**Statut :** Implémenté (octobre 2026)

---

## Problème rencontré

Les avis ne s’affichaient plus, ni en local ni en production :

- L’ancienne API Place Details répondait `REQUEST_DENIED` : facturation non activée sur le projet Google Cloud.
- Places API (New) était plafonnée à **100 appels par jour**, partagés entre local et production (même clé).
- Le layout public appelait Google **à chaque page** :
  - en local, le cache Rails est un `NullStore` ;
  - en production, le cache Redis était cassé : le certificat auto-signé de Heroku Redis faisait échouer chaque connexion, et Rails ignorait l’erreur sans bruit. Redis restait vide (0 clé).
- Résultat : quota épuisé, puis `403 PERMISSION_DENIED` tant que la facturation n’était pas liée au projet.

---

## Solution

```text
Heroku Scheduler (1x/jour) → google_places:refresh → Places API (New) → Redis
Pages publiques → GooglePlacesService.fetch → Redis (lecture seule, jamais d'appel Google)
```

| Élément | Rôle |
|---|---|
| `GooglePlacesService.fetch` | Lit le cache : avis du jour (24 h), sinon dernier succès (7 jours). Aucun appel réseau. |
| `GooglePlacesService.refresh!` | Un appel Places API (New). Écrit le cache seulement si Google renvoie une note. En cas d’échec, garde les anciens avis. |
| `bin/rails google_places:refresh` | Tâche à planifier une fois par jour. Affiche la note, ou sort en erreur. |
| Cache local | Fichier `tmp/cache/google_places` (le cache Rails de dev n’est pas partagé avec la tâche rake). |
| Cache production | Heroku Redis via `Rails.cache`. |

Google renvoie au plus **5 avis**, choisis comme « les plus pertinents » (pas de tri par date dans l’API New), plus la note et le nombre total d’avis.

L’ancienne API (legacy) a été entièrement retirée.

### Fichiers

- `app/services/google_places_service.rb`
- `lib/tasks/google_places.rake`
- `config/environments/production.rb` (cache Redis)
- `app/views/public/pages/la_boutique/_section_google_reviews.html.erb`
- `spec/services/google_places_service_spec.rb`

---

## Configuration Google Cloud

- **Compte :** Google a1soir, organisation `contact-org`, projet **My First Project** (n° 891112595546)
- **Facturation :** compte de facturation **lié au projet** (ajouter une carte ne suffit pas)
- **API activée :** Places API (New), `places.googleapis.com`
- **Clé `GOOGLE_PLACES_API_KEY` :**
  - restriction d’application : **Aucune** (appels côté serveur ; un référent HTTP bloque, et Heroku n’a pas d’IP fixe) ;
  - restriction d’API : **Places API (New)** uniquement.
- **Variables :** `GOOGLE_PLACES_API_KEY` et `GOOGLE_PLACE_ID` dans `.env` (local) et dans la config Heroku (production)

---

## Configuration Heroku Redis (app `a1soir-2`)

- Add-on `heroku-redis` Mini (`redis-rectangular-47621`) : 25 Mo, 20 connexions, TLS obligatoire, **sans persistance** (un redémarrage vide le cache ; le refresh quotidien le remplit à nouveau).
- `production.rb` :
  - `ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }` — obligatoire avec le certificat auto-signé Heroku ;
  - `error_handler` — écrit les erreurs Redis dans les logs (mot de passe d’URL masqué en `[FILTERED]`).
- Politique mémoire : **`allkeys-lru`** (adaptée à un cache).
- Autres usages du cache réactivés par le correctif : limite anti-abus des mensurations, rapport de stock annuel admin.

---

## Commandes importantes

### Avis Google

```bash
# Local
bin/rails google_places:refresh

# Production
heroku run -a a1soir-2 bin/rails google_places:refresh

# Vérifier ce qui est en cache (production)
heroku run -a a1soir-2 bin/rails runner "d = GooglePlacesService.fetch; puts d ? d.slice(:rating, :user_rating_count) : 'vide'"
```

Planification (en place) : job Scheduler `bundle exec rails google_places:refresh`, Standard-1X, **tous les jours à 4:00 AM UTC**. Tableau de bord : `heroku addons:open scheduler -a a1soir-2` (colonne « Last Run »).

```bash
# Vérifier le passage du Scheduler (heroku logs renvoie 100 lignes par défaut)
heroku logs -a a1soir-2 --dyno scheduler -n 1500 | grep google_places

# Tester sans attendre, comme le Scheduler (consomme 1 appel Google)
heroku run:detached -a a1soir-2 bin/rails google_places:refresh
heroku logs -a a1soir-2 --dyno run.XXXX   # numéro affiché par la commande précédente
```

Ligne attendue : `[google_places] Note 4.8 sur 216 avis, 5 avis en cache.` puis `Process exited with status 0`.

### Vérifications Redis (lecture seule)

```bash
heroku addons -a a1soir-2
heroku redis:info -a a1soir-2

# L'app joint Redis ? Doit afficher PONG
heroku run -a a1soir-2 bin/rails runner "puts Rails.cache.redis.then(&:ping)"

# Erreurs de cache : normalement rien
heroku logs --tail -a a1soir-2 | grep RedisCacheStore

# Noms des variables, sans les valeurs
heroku config -a a1soir-2 --shell | cut -d= -f1
```

Console Redis : `heroku redis:cli -a a1soir-2`, puis uniquement `PING`, `DBSIZE`, `INFO keyspace`, `INFO memory`, `SCAN 0 COUNT 100`, `TYPE <clé>`, `TTL <clé>`.  
À ne pas utiliser : `FLUSHALL`, `FLUSHDB`, `DEL`, `SET`, `CONFIG SET`, `KEYS *`.

### Réglage (déjà appliqué)

```bash
heroku redis:maxmemory -a a1soir-2 --policy allkeys-lru
```

---

## Dépannage

| Message | Cause probable |
|---|---|
| `429 Quota exceeded` | Trop d’appels dans la journée. Le quota repart vers 9 h (heure de Paris). |
| `403 PERMISSION_DENIED` | Facturation non liée au projet, Places API (New) désactivée, ou clé restreinte. |
| `REQUEST_DENIED: You must enable Billing` | Facturation non liée au projet Google Cloud. |
| `certificate verify failed` (Redis) | `ssl_params` absent de la config du cache. |
| Tâche OK mais avis absents en prod | Vérifier `PONG` et `DBSIZE` ; erreurs dans les logs `RedisCacheStore`. |

Les 201 alertes Search Console « aggregateRating / review manquant » concernent les **fiches produit** : il n’y a pas d’avis par produit, c’est normal. Ne pas y recopier la note de la boutique (interdit par Google).
