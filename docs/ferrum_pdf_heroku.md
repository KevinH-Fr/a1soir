# Ferrum PDF — Heroku (`a1soir-2`)

**Aujourd’hui** : PDF métier = `wicked_pdf` / `wkhtmltopdf-heroku`. PoC Ferrum = [`FerrumPdfFromHtml`](../app/services/ferrum_pdf_from_html.rb) + [`FerrumPdfRenderable`](../app/controllers/concerns/ferrum_pdf_renderable.rb) (inclus dans chaque contrôleur concerné, ex. `FerrumPdfTestsController`).

Ferrum **ne tourne pas en prod** tant que le buildpack Chrome n’est pas ajouté.

## Mise en place (Heroku-24 / Cedar)

Buildpack à utiliser : [`heroku-community/chrome-for-testing`](https://github.com/heroku/heroku-buildpack-chrome-for-testing) (pas `heroku/google-chrome`, incompatible Heroku-24).

```bash
heroku buildpacks:add -i 1 heroku-community/chrome-for-testing -a a1soir-2
git push heroku main
heroku run "which chrome && chrome --version" -a a1soir-2
```

`chrome` est dans le PATH — pas de `FERRUM_BROWSER_PATH` à configurer.

En production, [`ferrum_pdf_from_html.rb`](../app/services/ferrum_pdf_from_html.rb) ajoute déjà `no-sandbox`, `disable-dev-shm-usage`, `disable-gpu`.

## Test

Home admin → **Test PDF Ferrum** / **Test mail Ferrum**, ou `/admin/ferrum_pdf_test.pdf` (admin connecté).

## Surveiller

- Logs : R14 (mémoire), H12 (timeout) — Chromium est plus gourmand que wkhtmltopdf.
- Dyno **Standard-2X** si PDF fréquents ou lourds.

## Plus tard (migration wicked → Ferrum)

Buildpack Chrome validé → migrer commandes / étiquettes / stock → retirer `wkhtmltopdf-heroku` et buildpack wkhtmltopdf.



Pour une app Rails Heroku, je te conseille de lancer Ferrum dans un job worker, pas directement dans une requête web, surtout pour générer des PDF/screenshots.

verif pdf reporting stock bien protégé admin seul pas vendeur