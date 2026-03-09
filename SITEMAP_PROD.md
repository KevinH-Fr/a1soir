## Commandes sitemap (local, host de prod)

Générer / regénérer le sitemap en local en utilisant `https://a1soir.com` comme host :

```bash
cd ~/ror/a1soir
SITEMAP_HOST=https://a1soir.com bundle exec rake sitemap:refresh
```

Vérifier les fichiers générés dans `public/` :

```bash
cd ~/ror/a1soir
ls public/sitemap*
```


     heroku run bundle exec rake sitemap:refresh -a a1soir-2
     heroku run "ls public/sitemap*" -a a1soir-2