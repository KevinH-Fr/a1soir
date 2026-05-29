# Ferrum PDF — Heroku (`a1soir-2`)

**Stack PDF** : tous les documents (commandes, étiquettes, reporting stock) passent par Ferrum + headless Chrome via [`FerrumPdfFromHtml`](../app/services/ferrum_pdf_from_html.rb) et le concern [`PdfRenderable`](../app/controllers/concerns/pdf_renderable.rb).

## Prérequis Heroku (Heroku-24 / Cedar)

Buildpack : [`heroku-community/chrome-for-testing`](https://github.com/heroku/heroku-buildpack-chrome-for-testing) (pas `heroku/google-chrome`, incompatible Heroku-24).

```bash
heroku buildpacks:add -i 1 heroku-community/chrome-for-testing -a a1soir-2
git push heroku main
heroku run "which chrome && chrome --version" -a a1soir-2
```

`chrome` est dans le PATH — pas de `FERRUM_BROWSER_PATH` à configurer.

En production, [`ferrum_pdf_from_html.rb`](../app/services/ferrum_pdf_from_html.rb) ajoute `no-sandbox`, `disable-dev-shm-usage`, `disable-gpu`.

Retirer le buildpack `wkhtmltopdf` s'il est encore présent (migration terminée).

## Documents concernés

| Document | Contrôleur | Méthode |
|----------|------------|---------|
| Commandes (devis, factures…) | `DocEditionsController` | `send_pdf_with_header_footer` / `deliver_pdf_with_header_footer_email` |
| Reporting stock | `StockController#report` | `send_pdf` |
| Étiquettes 2×2 | `EtiquettesController#generate_pdf` | `send_pdf` |

## Surveiller

- Logs : R14 (mémoire), H12 (timeout) — Chromium est plus gourmand que l'ancien wkhtmltopdf.
- Dyno **Standard-2X** si PDF fréquents ou lourds.

## Helpers

- [`PdfHelper`](../app/helpers/pdf_helper.rb) — images base64 pour header/footer Chrome
- Layout unifié [`layouts/pdf.html.erb`](../app/views/layouts/pdf.html.erb) — Bootstrap 5 + `document.css` inline
