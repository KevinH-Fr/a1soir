# Bootstrap Icons — SVG utilisés

Fichiers versionnés : `public/icons/bootstrap/*.svg`, `public/icons/bootstrap/used.txt`, `app/assets/stylesheets/vendor/bootstrap-icons-used.css`.

Le site charge le CSS subset (plus de police `.woff2`).

## Mettre à jour (SVG + liste + CSS)

Tâche rake **locale, non commitée** — scanne le code, télécharge les SVG, regénère `used.txt` et `bootstrap-icons-used.css` :

```bash
bundle exec rake icons:bootstrap:sync
```

Résumé affiché : ignorées (déjà local), téléchargées, introuvables, réseau, supprimées, présentes.

Forcer le re-téléchargement de tous les SVG :

```bash
ICONS_FORCE=1 bundle exec rake icons:bootstrap:sync
```

Puis committer les artefacts :

```bash
git add public/icons/bootstrap/*.svg public/icons/bootstrap/used.txt app/assets/stylesheets/vendor/bootstrap-icons-used.css
```

## Ajouter une icône

Utiliser `bi bi-nom-icone` (ou `icon: "nom-icone"`) dans le code, relancer la commande ci-dessus.

## Fichiers locaux (gitignored)

- `lib/tasks/bootstrap_icons.rake`
- `lib/bootstrap_icons/builder.rb`

Sur une nouvelle machine, recopier ces fichiers depuis un poste existant.

## Ancien pack (plus utilisé)

- `app/assets/stylesheets/vendor/bootstrap-icons.min.css`
- `public/fonts/bootstrap-icons.woff2` / `.woff`

Supprimables une fois la prod vérifiée.
