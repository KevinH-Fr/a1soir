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


