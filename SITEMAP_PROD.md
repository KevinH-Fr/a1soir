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

et ensuite le push en prod maj le sitemap en prod

fonctionne avec le sitemap gz et que les pages statiques, voir pour pages categories et produits

donc cest le sitemap dans le repo local qui est push en prod et utilisé


