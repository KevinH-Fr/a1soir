## Sitemap production FR/EN

Le sitemap est genere en local, versionne dans le repo, puis deploye en production.
Le host canonique doit rester `https://a1soir.com`.

### 1) Regenerer le sitemap (avec host de prod)

```bash
cd ~/ror/a1soir
SITEMAP_HOST=https://a1soir.com bundle exec rake sitemap:refresh
```

### 2) Verifier les fichiers generes

```bash
cd ~/ror/a1soir
ls public/sitemap*
```

### 3) Verifier le contenu FR/EN

Le sitemap doit contenir:
- des URLs absolues sur `https://a1soir.com`
- les pages en `/fr/...` et `/en/...`
- aucune URL publique sans locale
- aucune URL admin

### 4) Mise en production

Le sitemap utilise en production est celui present dans le repo deploye.

### 5) robots.txt

Le fichier `public/robots.txt` doit declarer:

```txt
Sitemap: https://a1soir.com/sitemap.xml.gz
```

### 6) Validation SEO apres deploiement

- Ouvrir `https://a1soir.com/sitemap.xml.gz` et verifier qu'il est accessible.
- Re-soumettre le sitemap dans Google Search Console.
- Verifier que Google detecte bien les URLs FR et EN.
- Controler qu'il n'y a pas d'erreurs d'indexation ou d'URLs "dupliquees sans canonique selectionnee".

## Google Merchant Center (feed produits)

En production (Heroku), le feed **n'est pas** un fichier statique dans `public/` : le filesystem est ephemere et non partage entre dynos. L'URL publique reste :

`https://a1soir.com/google_merchant_feed.xml`

Rails sert ce chemin via `GoogleMerchantFeedsController` : le XML est **genere a la demande** a chaque requete (`GoogleMerchant::StaticFeed.to_xml`). Pas de cache Redis dedie au feed ; pas de job Heroku Scheduler obligatoire.

### Planification des mises a jour

Configurer la **date et l'heure de recuperation du flux** dans Google Merchant Center (pas sur Heroku). Google appelle l'URL a ce moment-la ; une generation complete du XML a chaque fetch est attendue.

### Verification

- Ouvrir l'URL du feed et verifier le `Content-Type` / le contenu XML (`curl -sI` ou navigateur).
- Dans Merchant Center, surveiller les erreurs de fetch au prochain creneau planifie.
- Le fichier `public/google_merchant_feed.xml` est ignore par git ; une copie locale optionnelle peut etre generee avec `GoogleMerchant::StaticFeed.write!` uniquement pour le debug.