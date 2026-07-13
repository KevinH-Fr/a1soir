# Vérification SEO prod — commandes

Tests sur `https://a1soir.com` après déploiement.

Produit de référence : **Louana** (`louana-robe-longue-bustier-drape-satin-fendue-4111`)

---

## 1. Fichiers statiques

```bash
curl -s https://a1soir.com/robots.txt
curl -s https://a1soir.com/llms.txt
curl -sI https://a1soir.com/sitemap.xml.gz | head -5
```

Attendu :
- `robots.txt` → `Sitemap:`, référence `llms.txt`, `User-agent: GPTBot` + `Allow: /`
- `llms.txt` → description boutique + liens pages clés
- sitemap → HTTP 200, `content-type: application/gzip`

---

## 2. Open Graph — `og:type`

```bash
curl -s https://a1soir.com/fr/home | grep 'og:type'

curl -s https://a1soir.com/fr/produit/louana-robe-longue-bustier-drape-satin-fendue-4111 | grep -E 'og:type|canonical|og:url'

curl -s "https://a1soir.com/fr/produit/louana-robe-longue-bustier-drape-satin-fendue-4111?back_url=%2Ffr%2Fproduits%3Fid%255B%255D%3D46%26id%255B%255D%3D44%26id%255B%255D%3D43" | grep canonical
```

Attendu :
- `/fr/home` → `content="website"`
- Louana → `content="product"`
- `canonical` = `https://a1soir.com/fr/produit/louana-robe-longue-bustier-drape-satin-fendue-4111` (sans `back_url`)

---

## 3. JSON-LD Product (sku, category, size)

```bash
curl -s https://a1soir.com/fr/produit/louana-robe-longue-bustier-drape-satin-fendue-4111 | grep -o '"@type":"Product"[^}]*'

curl -s https://a1soir.com/fr/produit/louana-robe-longue-bustier-drape-satin-fendue-4111 | grep -o '"sku":"[^"]*"'
```

Attendu :
- `"@type":"Product"`
- `"sku":"4111"` (id produit, pas ref fournisseur)
- `"category"`, `"size":"42"`, `"color"` si renseignés en base

---

## 4. SearchAction (recherche site)

```bash
curl -s https://a1soir.com/fr/home | grep -o 'SearchAction\|search_term_string'

curl -s "https://a1soir.com/fr/produits?q%5Bnom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont%5D=louana" | grep -i louana
```

Attendu :
- `SearchAction` + `urlTemplate` + `{search_term_string}` dans le JSON-LD
- recherche `louana` → fiche Louana dans les résultats

---

## 5. Meta catégorie catalogue

```bash
curl -s https://a1soir.com/fr/produits | grep -E '<title>|meta name="description"'

curl -s https://a1soir.com/fr/produits/accessoires-43 | grep -E '<title>|meta name="description"'

curl -s "https://a1soir.com/fr/produits?id%5B%5D=46&id%5B%5D=44&id%5B%5D=43" | grep '<title>'

curl -s https://a1soir.com/fr/produits | grep ItemList
```

Attendu :
- index → title « Nos produits »
- catégorie seule (`accessoires-43`) → title `accessoires | Autour D'Un Soir`
- multi-catégories (`id[]=46&44&43`) → title générique « Nos produits »
- `ItemList` présent sur l'index si produits affichés

---

## 6. noindex pages transactionnelles

```bash
curl -s https://a1soir.com/fr/cart | grep robots

curl -s https://a1soir.com/fr/status_payment/ID_PAIEMENT | grep robots
```

Attendu :
- panier → `noindex, nofollow`
- statut paiement (après achat test) → `noindex, nofollow`

---

## 7. Outils externes (navigateur)

- [Google Rich Results Test](https://search.google.com/test/rich-results?url=https%3A%2F%2Fa1soir.com%2Ffr%2Fproduit%2Flouana-robe-longue-bustier-drape-satin-fendue-4111) → `Product` détecté
- [Meta Sharing Debugger](https://developers.facebook.com/tools/debug/?q=https%3A%2F%2Fa1soir.com%2Ffr%2Fproduit%2Flouana-robe-longue-bustier-drape-satin-fendue-4111) → `og:type: product`

---

## Prérequis

- `SHOP_PASSWORD_ENABLED` désactivé en prod (sinon curl bloqué)
- Fichiers déployés : `public/robots.txt`, `public/llms.txt` + changements Rails
