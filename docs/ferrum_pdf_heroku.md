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
- Timeout Ferrum : `FERRUM_PDF_TIMEOUT` (défaut **60** s) — voir [`ferrum_pdf_from_html.rb`](../app/services/ferrum_pdf_from_html.rb).
- Attente images/réseau avant PDF : `FERRUM_PDF_IMAGE_WAIT` (défaut **15** s, plafonné par `FERRUM_PDF_TIMEOUT`).
- Si R14 persiste sur gros PDF commande : `WEB_CONCURRENCY=1` libère de la baseline (option Heroku).

## Helpers

- [`PdfHelper`](../app/helpers/pdf_helper.rb) — **corps** :
  - commandes : `pdf_product_thumb_tag` (`w_80` / `w_40`)
  - étiquettes : `pdf_product_thumb_tag` (`w_400` pour la photo produit)
  - **header/footer / QR** : `pdf_image_tag` (base64 embarqué, requis pour les templates d'en-tête Chrome)
- Layout unifié [`layouts/pdf.html.erb`](../app/views/layouts/pdf.html.erb) — Bootstrap 5 + `document.css` inline

## Attente chargement (Ferrum)

Après `page.content = html`, [`FerrumPdfFromHtml`](../app/services/ferrum_pdf_from_html.rb) :

1. Attend que toutes les `<img>` soient chargées (Promise JS, dont URLs Cloudinary)
2. Puis `page.network.wait_for_idle` (Bootstrap CDN, etc.)
3. Puis `page.pdf` — **plus de `sleep` fixe**

Checklist prod après deploy :

- Gros PDF **commande** : toutes les vignettes articles visibles
- PDF **étiquettes** (4+ produits) : photos produit visibles

## Vérifier taille HTML (gros PDF commande)

```ruby
# rails runner — remplacer doc_edition_id
de = DocEdition.find(ID)
html = Admin::DocEditionsController.render(
  template: "admin/pdf_commande/document",
  layout: "pdf",
  assigns: { doc_edition: de }
)
puts "#{html.bytesize / 1024} KB"
```

Après optimisation vignettes : typiquement **< 1 Mo** (vs dizaines de Mo en base64 full size).
