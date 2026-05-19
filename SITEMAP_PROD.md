## Sitemap production FR/EN

Le sitemap est genere en local (avec acces a la base de donnees), versionne dans le repo (`public/sitemap*.gz`), puis deploye en production.
Le host canonique doit rester `https://a1soir.com`.

Google le decouvre via `public/robots.txt` (`Sitemap: https://a1soir.com/sitemap.xml.gz`). Ce fichier est **distinct** du feed Google Merchant Center (Shopping).

### Contenu du sitemap (`config/sitemap.rb`)

| Type d'URL | Exemple | Perimetre |
|------------|---------|-----------|
| Pages statiques | `/fr/home`, `/en/contact`, … | Liste fixe dans `config/sitemap.rb` |
| Categories | `/fr/produits/robes-12`, `/en/produits/...` | `CategorieProduit.not_service` |
| Fiches produit | `/fr/produit/robe-123`, `/en/produit/...` | `Produit.actif` + `eshop: true` + `today_availability: true` |

Chaque URL catalogue est presente en **fr** et **en**. Aucune URL admin.

**Quand regenerer :** apres deploiement du nouveau `config/sitemap.rb`, import catalogue massif, ou changements importants de disponibilite (`today_availability`).

---

### 1) Regenerer le sitemap (host de prod)

La generation lit la base locale (ou celle pointee par `DATABASE_URL`). Utiliser une base a jour si possible.

```bash
cd ~/ror/a1soir
SITEMAP_HOST=https://a1soir.com bundle exec rake sitemap:refresh
```

### 2) Verifier les fichiers generes

```bash
ls -la public/sitemap*
```

Fichiers attendus : au minimum `public/sitemap.xml.gz` (et eventuellement un index si le volume depasse la limite d'un seul fichier).

### 3) Verifier le contenu FR/EN

Controles manuels sur le XML decompressé :

```bash
gunzip -c public/sitemap.xml.gz | head -50
gunzip -c public/sitemap.xml.gz | grep -c '<loc>'
gunzip -c public/sitemap.xml.gz | grep '/fr/produit/' | head -5
gunzip -c public/sitemap.xml.gz | grep '/en/produits/' | head -5
```

Le sitemap doit contenir :

- des URLs **absolues** sur `https://a1soir.com`
- les pages en `/fr/...` et `/en/...`
- des URLs **categories** (`/fr/produits/...`, `/en/produits/...`)
- des URLs **fiches produit** (`/fr/produit/...`, `/en/produit/...`)
- **aucune** URL publique sans locale (`/produit/...` sans `/fr` ou `/en`)
- **aucune** URL admin

### 4) Versionner et deployer

```bash
git add config/sitemap.rb public/sitemap.xml.gz
git commit -m "Regenerer le sitemap (pages, categories, produits FR/EN)"
git push
# puis deploiement habituel (ex. Heroku)
```

Le sitemap servi en production est celui **present dans le repo deploye** (fichier statique dans `public/`), pas regenere a chaque requete.

### 5) Verifier en production

Apres deploiement :

- Ouvrir [https://a1soir.com/sitemap.xml.gz](https://a1soir.com/sitemap.xml.gz) (telechargement / decompression OK).
- Verifier quelques URLs produit et categorie dans le fichier.
- Confirmer que `https://a1soir.com/robots.txt` declare bien :

```txt
Sitemap: https://a1soir.com/sitemap.xml.gz
```

### 6) Soumettre / mettre a jour dans Google Search Console

1. Aller sur [Google Search Console](https://search.google.com/search-console) → propriete `a1soir.com`.
2. Menu **Indexation** → **Sitemaps**.
3. Si le sitemap `https://a1soir.com/sitemap.xml.gz` n'y est pas encore : l'ajouter dans « Ajouter un sitemap ».
4. S'il existe deja : apres un nouveau deploiement, Google le re-crawl automatiquement ; on peut aussi **resoumettre** l'URL du sitemap pour accelerer la prise en compte.
5. Surveiller pendant quelques jours :
   - URLs decouvertes / indexees
   - erreurs d'exploration sur les fiches `/fr/produit/...` et `/en/produit/...`
   - avertissements « URL en double » ou canonique (hreflang deja en place sur le site public)

**Note :** Search Console concerne l'**indexation organique**. Le feed Merchant Center (section ci-dessous) est un canal separe pour Google Shopping.

### 7) Validation SEO (checklist)

- [ ] `sitemap.xml.gz` accessible en prod
- [ ] Presence d'URLs categories et produits FR + EN
- [ ] Sitemap declare dans `robots.txt`
- [ ] Sitemap soumis ou a jour dans Search Console
- [ ] Pas d'erreurs d'indexation massives sur les nouvelles URLs
- [ ] Regenerer le sitemap apres gros changements catalogue (puis re-deployer)

---

## Google Merchant Center (feed produits)

En production (Heroku), le feed **n'est pas** un fichier statique dans `public/` : le filesystem est ephemere et non partage entre dynos. L'URL publique reste :

`https://a1soir.com/google_merchant_feed.xml`

Rails sert ce chemin via `GoogleMerchantFeedsController` : le XML est **genere a la demande** a chaque requete (`GoogleMerchant::StaticFeed.to_xml`). Pas de cache Redis dedie au feed ; pas de job Heroku Scheduler obligatoire.

Perimetre du feed (plus strict que le sitemap) : produits actifs, `eshop`, image, `prixvente > 0`, etc. Voir `GoogleMerchant::FeedBuilder`.

### Planification des mises a jour

Configurer la **date et l'heure de recuperation du flux** dans Google Merchant Center (pas sur Heroku). Google appelle l'URL a ce moment-la ; une generation complete du XML a chaque fetch est attendue.

### Verification

- Ouvrir l'URL du feed et verifier le `Content-Type` / le contenu XML (`curl -sI` ou navigateur).
- Dans Merchant Center, surveiller les erreurs de fetch au prochain creneau planifie.
- Le fichier `public/google_merchant_feed.xml` est ignore par git ; une copie locale optionnelle peut etre generee avec `GoogleMerchant::StaticFeed.write!` uniquement pour le debug.
