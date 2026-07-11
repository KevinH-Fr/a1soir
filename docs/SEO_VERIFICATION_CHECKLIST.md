# Vérification SEO prod — commandes

Tests à lancer après déploiement sur `https://a1soir.com`.

Remplacer `PRODUIT_SLUG-ID` par une vraie fiche (ex. `robe-de-mariee-dentelle-bustier-abigail-2748`)  
Remplacer `CATEGORIE_SLUG-ID` par une vraie catégorie (ex. `accessoires-43`)

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
curl -s https://a1soir.com/fr/produit/PRODUIT_SLUG-ID | grep -E 'og:type|canonical|og:url'
curl -s "https://a1soir.com/fr/produit/PRODUIT_SLUG-ID?back_url=%2Ffr%2Fproduits" | grep canonical
```

Attendu :
- `/fr/home` → `content="website"`
- fiche produit → `content="product"`
- `canonical` / `og:url` sans `back_url`

---

## 3. JSON-LD Product (sku, category, size)

```bash
curl -s https://a1soir.com/fr/produit/PRODUIT_SLUG-ID | grep -o '"@type":"Product"[^}]*'
curl -s https://a1soir.com/fr/produit/PRODUIT_SLUG-ID | grep -o '"sku":"[^"]*"'
```

Attendu :
- `"@type":"Product"`
- `"sku"` = **id produit** (ex. `"2748"`), pas la ref fournisseur
- `"category"` et `"size"` si renseignés en base

---

## 4. SearchAction (recherche site)

```bash
curl -s https://a1soir.com/fr/home | grep -o 'SearchAction\|search_term_string'
curl -s "https://a1soir.com/fr/produits?q%5Bnom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont%5D=TERME_RECHERCHE" | grep -i TERME_RECHERCHE
```

Attendu :
- `SearchAction` + `urlTemplate` + `{search_term_string}` dans le JSON-LD
- recherche avec un terme connu → produits correspondants

---

## 5. Meta catégorie catalogue

```bash
curl -s https://a1soir.com/fr/produits | grep -E '<title>|meta name="description"'
curl -s https://a1soir.com/fr/produits/CATEGORIE_SLUG-ID | grep -E '<title>|meta name="description"'
curl -s https://a1soir.com/fr/produits | grep ItemList
```

Attendu :
- index → title « Nos produits »
- catégorie → title `{nom catégorie} | Autour D'Un Soir`
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

- [Google Rich Results Test](https://search.google.com/test/rich-results) → fiche produit, `Product` détecté
- [Meta Sharing Debugger](https://developers.facebook.com/tools/debug/) → fiche produit, `og:type: product`

---

## Prérequis

- `SHOP_PASSWORD_ENABLED` désactivé en prod (sinon curl bloqué)
- Fichiers déployés : `public/robots.txt`, `public/llms.txt` + changements Rails
