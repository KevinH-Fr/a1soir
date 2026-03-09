## Générer un sitemap de production et le committer

Objectif : avoir un `public/sitemap.xml.gz` **basé sur les données de production** (vrais produits / catégories), puis le committer pour qu’il soit toujours servi par l’app.

---

### 1. Générer le sitemap sur la base de données de production (Heroku)

Depuis ta machine locale, dans le projet :

```bash
cd ~/ror/a1soir
heroku run bundle exec rake sitemap:refresh -a a1soir-2
```

- Cette commande lance `sitemap:refresh` **sur Heroku**, en `RAILS_ENV=production`, donc avec la vraie base de données.
- Le fichier est créé sur le dyno dans `/app/public/sitemap.xml.gz`.

---

### 2. Récupérer le fichier généré vers ta machine locale

Toujours depuis le dossier du projet :

```bash
cd ~/ror/a1soir
heroku run "cat public/sitemap.xml.gz" -a a1soir-2 > public/sitemap.xml.gz
```

- `cat public/sitemap.xml.gz` lit le fichier sur le dyno.
- La redirection `> public/sitemap.xml.gz` enregistre **le sitemap de prod** dans ton dossier `public/` local.

---

### 3. Committer le sitemap dans le dépôt

Ajoute et committe le fichier :

```bash
cd ~/ror/a1soir
git add public/sitemap.xml.gz
git commit -m "Add sitemap.xml.gz generated from production data"
git push
```

- Le sitemap est maintenant versionné et inclus dans le slug Heroku à chaque déploiement.
- L’URL `https://a1soir.com/sitemap.xml.gz` doit répondre **200** et être lisible par Google.

---

### 4. Vérifier dans Google Search Console

1. Ouvrir `https://a1soir.com/sitemap.xml.gz` dans ton navigateur (200 attendu, pas 404).
2. Dans Search Console, déclarer ou mettre à jour le sitemap avec exactement cette URL :

```text
https://a1soir.com/sitemap.xml.gz
```

3. Si un ancien sitemap était en erreur 404, tu peux le supprimer de la liste des sitemaps envoyés.

