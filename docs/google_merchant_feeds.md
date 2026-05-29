# Google Merchant Feeds

Ce document regroupe les informations de production pour les flux Google
Merchant Center A1soir.

## Flux Produit Principal

URL publique :

```txt
https://a1soir.com/google_merchant_feed.xml
```

En production Heroku, ce flux n'est pas un fichier statique dans `public/`.
Rails sert ce chemin via `GoogleMerchantFeedsController` et genere le XML a la
demande avec `GoogleMerchant::StaticFeed.to_xml`.

Le perimetre est volontairement plus strict que le sitemap : produits actifs,
diffuses e-shop, avec image, `prixvente > 0`, etc. La source de verite est
`GoogleMerchant::FeedBuilder`.

L'identifiant produit actuel est de la forme :

```xml
<g:id>produit-195</g:id>
```

Cet identifiant doit rester strictement identique dans tous les flux Merchant
lies au meme produit.

### Regroupement variantes (`g:item_group_id`)

Google impose **1 a 50 caracteres** (alphanumeriques, tirets, underscores) pour
`item_group_id`. Le site utilise un `handle` derive du titre SEO (`nom.parameterize`),
qui peut depasser cette limite apres renommage (ex. titres longs type Harper).

Le flux normalise donc la valeur via `GoogleMerchant::FeedFormatting.item_group_id` :

- handle <= 50 caracteres : valeur identique au `handle` en base ;
- handle > 50 : forme raccourcie deterministe (`prefixe` + hash), **identique entre
  toutes les variantes** d'une meme famille ;
- les URLs du site (`/fr/produit/<handle>-<id>`) ne sont pas modifiees.

Verification apres deploy :

```bash
curl -sL https://a1soir.com/google_merchant_feed.xml | grep -E 'item_group_id|harper'
```

Dans Merchant Center : recuperation manuelle du flux principal, puis controle des
diagnostics (disparition de l'alerte « Texte trop long : item_group_id » sous 24-48 h).

Audit console (familles concernees) :

```ruby
Produit.where("CHAR_LENGTH(handle) > 50").distinct.pluck(:handle, :nom)
```

## Flux Inventaire Local

URL publique :

```txt
https://a1soir.com/google_local_inventory_feed.xml
```

Route Rails : `GET /google_local_inventory_feed.xml` →
`GoogleMerchantFeedsController#local_inventory` →
`GoogleMerchant::LocalInventoryFeed.to_xml`.

Ce deuxieme flux doit contenir uniquement les informations d'inventaire magasin,
pas la fiche produit complete.

Champs attendus par item :

```xml
<item>
  <g:id>produit-195</g:id>
  <g:store_code>14941325208231197348</g:store_code>
  <g:availability>in_stock</g:availability>
  <g:quantity>1</g:quantity>
  <g:price>695.00 EUR</g:price>
  <g:pickup_method>buy</g:pickup_method>
  <g:pickup_sla>next_day</g:pickup_sla>
</item>
```

Code magasin A1soir Cannes :

```txt
14941325208231197348
```

Le flux local doit reprendre le meme `g:id` que le flux principal. Exemple :

```txt
Flux principal : <g:id>produit-195</g:id>
Flux local     : <g:id>produit-195</g:id>
```


## Logique Produit Locale

Selection recommandee :

- Repartir du scope du flux principal pour garantir que les IDs existent dans
  `google_merchant_feed.xml`.
- Ajouter le filtre `today_availability: true`.
- Conserver uniquement les produits avec `prixvente > 0`.

Mapping simple :

```ruby
availability = "in_stock"
quantity = produit.statut_disponibilite(Time.current, Time.current)[:disponibles]
quantity = 1 if quantity.to_i <= 0
pickup_sla = "next_day"
```

`next_day` est plus prudent que `same_day` au depart.

Aucun cache specifique n'est necessaire pour commencer si l'endpoint repond
rapidement.

## Planification Merchant Center

Configurer la recuperation dans Google Merchant Center, pas via un job Heroku
obligatoire.

Ordre conseille :

1. Flux produit principal : 04h00.
2. Flux inventaire local : 05h00.

Le flux local doit etre recupere apres le flux principal, car Google doit deja
connaitre les produits avant de recevoir leur inventaire magasin.

## Verification Technique

Verifier le flux principal :

```bash
curl -sI https://a1soir.com/google_merchant_feed.xml
curl -s https://a1soir.com/google_merchant_feed.xml | head
```

Verifier le flux local :

```bash
curl -I https://a1soir.com/google_local_inventory_feed.xml
curl https://a1soir.com/google_local_inventory_feed.xml | head
```

Attendus :

```txt
HTTP/2 200
content-type: application/xml
```

Le XML doit contenir :

```xml
xmlns:g="http://base.google.com/ns/1.0"
<g:store_code>14941325208231197348</g:store_code>
```

Comparer un ID entre les deux flux :

```bash
curl https://a1soir.com/google_merchant_feed.xml | grep "produit-195"
curl https://a1soir.com/google_local_inventory_feed.xml | grep "produit-195"
```

## Verification Merchant Center

Apres import, verifier dans Merchant Center :

- Le flux local est recupere sans erreur.
- Le `store_code` est reconnu.
- Les erreurs de donnees d'inventaire en magasin manquantes diminuent.
- Les produits ne sont pas rejetes pour `id` introuvable.
- Le nombre de produits locaux correspond au nombre envoye.

Erreurs probables :

- `id` introuvable : `g:id` different entre flux principal et flux local.
- Code magasin invalide : mauvais `store_code`.
- Prix invalide : format different de `695.00 EUR`.
- Disponibilite invalide : valeur non reconnue par Google.
- Retrait non eligible : incoherence entre `pickup_method` et `pickup_sla`.

## Variables D'Environnement (optionnel)

| Variable | Role |
|----------|------|
| `MERCHANT_FEED_HOST` | Host canonique des deux flux |
| `MERCHANT_FEED_ID_PREFIX` | Prefixe `g:id` (defaut : `produit`) |
| `MERCHANT_LOCAL_STORE_CODE` | Code magasin (defaut : Cannes) |
| `MERCHANT_LOCAL_FEED_LIMIT` | Limite ponctuelle du nombre de produits (test uniquement) |
| `MERCHANT_LOCAL_FEED_CHANNEL_TITLE` | Titre du channel RSS local |
| `MERCHANT_LOCAL_FEED_CHANNEL_DESCRIPTION` | Description du channel RSS local |

## Ordre De Mise En Place

1. Deployer le code (flux local implemente dans Rails).
2. Tester l'URL avec `curl`.
3. Ajouter le flux dans Merchant Center.
4. Lancer une recuperation manuelle.
5. Corriger les erreurs eventuelles.
6. Etendre ou confirmer l'envoi de tous les produits disponibles en boutique.
