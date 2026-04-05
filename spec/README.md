# Documentation des tests — Stripe e-shop

Ce document décrit la couverture de la suite de tests RSpec liée à la fonctionnalité e-shop Stripe et explique comment les exécuter.

---

## Table des matières

1. [Architecture générale](#architecture-générale)
2. [Couverture par fichier](#couverture-par-fichier)
   - [Modèles](#modèles)
   - [Services](#services)
   - [Mailers](#mailers)
   - [Requêtes HTTP](#requêtes-http)
3. [Exécuter les tests](#exécuter-les-tests)

---

## Architecture générale

Les tests couvrent l'intégralité du flux d'achat en ligne :

```
Client (navigateur)
  │
  ├─ Panier (session[:cart])          ← spec/requests/stripe_payments_spec.rb
  │                                      spec/requests/public/pages_spec.rb
  ├─ Checkout Stripe (redirection)    ← spec/requests/stripe_payments_spec.rb
  │
  ├─ Webhook Stripe                   ← spec/requests/webhooks/stripe_spec.rb
  │     └─ StripeCheckoutFulfillmentService
  │           ├─ StripePayment / StripePaymentItem  ← spec/models/stripe_payment_item_spec.rb
  │           ├─ StripeEshopCommandeService         ← spec/services/stripe_eshop_commande_service_spec.rb
  │           └─ StripePaymentMailer                ← spec/mailers/stripe_payment_mailer_spec.rb
  │
  └─ Disponibilité produit            ← spec/models/produit_spec.rb
        └─ ShippingCostService        ← spec/services/shipping_cost_service_spec.rb
```

---

## Couverture par fichier

### Modèles

#### `spec/models/produit_spec.rb` — 19 exemples

| Contexte | Ce qui est testé |
|---|---|
| `after_create` callback | Vérifie que `generate_qr` est appelé à la création |
| `#generate_qr` | Appelle le service `GenerateQr` avec le bon modèle |
| `#set_default_poids` | Poids par défaut à 2000 g si nil ; préserve la valeur explicite |
| `#statut_disponibilite` — sans vente | Retourne le stock initial complet comme disponible |
| `#statut_disponibilite` — ventes boutique | Déduit les articles vendus en boutique ; marque « indisponible » si stock épuisé ; ignore les articles en location |
| `#statut_disponibilite` — ventes e-shop | Déduit les `StripePaymentItem` payés ; ignore les paiements en attente ; cumule boutique + e-shop |
| `#update_today_availability` | Passe `today_availability` à `true` si stock dispo, à `false` si épuisé |

#### `spec/models/stripe_payment_item_spec.rb` — 5 exemples

| Contexte | Ce qui est testé |
|---|---|
| Callback `#update_produit_availability_if_paid` | Déclenche `update_today_availability` uniquement si le paiement est `paid` ; ne plante pas si `produit` est nil |
| Intégration `today_availability` | Met `today_availability` à `false` après épuisement du stock ; laisse `true` si paiement en attente |

---

### Services

#### `spec/services/shipping_cost_service_spec.rb` — 14 exemples

Teste `ShippingCostService.fee_cents_for(weight_g)` sur tous les paliers La Poste :

| Palier | Poids | Frais |
|---|---|---|
| 1 | 0 – 250 g | 7,00 € |
| 2 | 251 – 500 g | 8,00 € |
| 3 | 501 – 750 g | 9,00 € |
| 4 | 751 – 1 000 g | 9,00 € |
| 5 | 1 001 – 2 000 g | 10,00 € |
| Max | 14 001 – 15 000 g | 21,00 € |
| Au-delà | > 15 000 g | 21,00 € (dernier palier) |

Couvre également les paniers multi-produits (somme de poids, franchissement de palier, poids zéro, poids par défaut 2000 g).

#### `spec/services/stripe_checkout_fulfillment_service_spec.rb` — 17 exemples

Teste `StripeCheckoutFulfillmentService#fulfill!` appelé depuis le webhook Stripe.

| Scénario | Ce qui est testé |
|---|---|
| Paiement simple | Crée `StripePayment`, `StripePaymentItem`, `Commande` et `Article` |
| Idempotence | Ré-exécuter `fulfill!` avec le même `session_id` ne crée pas de doublons |
| Paiement non payé | Ne crée rien si `payment_status != "paid"` |
| E-mail client | Envoie `StripePaymentMailer#confirmation` si `customer_email` est présent |
| E-mail admin | Envoie `notification_admin` si `GMAIL_ACCOUNT` est défini ; pas d'envoi sinon |
| E-mail client absent | N'envoie que l'e-mail admin si `customer_email` est vide |
| Panier multi-produits | Crée un `StripePaymentItem` et un `Article` par ligne de commande |
| Variante taille | Lie le `StripePaymentItem` au bon `Produit` via `stripe_price_id` + `taille` |
| Variante couleur | Lie le `StripePaymentItem` au bon `Produit` via `stripe_price_id` + `couleur` |
| Deux variantes (S + L) | Crée les bons articles et les attache aux bonnes tailles |

#### `spec/services/stripe_eshop_commande_service_spec.rb` — 13 exemples

Teste `StripeEshopCommandeService#attach_commande_if_possible!`.

| Scénario | Ce qui est testé |
|---|---|
| Cas nominal | Crée une `Commande` liée au paiement avec `eshop: true`, `type_locvente: "vente"` |
| Articles | Crée un `Article` avec `locvente: "vente"` par `StripePaymentItem` |
| Client find-or-create | Crée un `Client` à partir de l'e-mail ; réutilise un client existant |
| Idempotence | N'ajoute pas une deuxième `Commande` si le paiement en a déjà une |
| Sans e-mail client | Ne crée pas de `Commande` si `customer_email` est vide |
| Sans `Profile` | Ne crée pas de `Commande` si aucun profil n'existe en base |
| Panier multi-produits | Crée un `Article` par ligne et les attache à la même `Commande` |
| **Race condition** | La boutique vend le dernier article avant que le webhook soit traité → `disponibles` passe à -1, `today_availability` bascule à `false` |

---

### Mailers

#### `spec/mailers/stripe_payment_mailer_spec.rb` — 13 exemples

| Méthode | Ce qui est testé |
|---|---|
| `#confirmation` | Destinataire = e-mail client ; sujet présent ; parties HTML + texte ; contient le nom du produit ; retour silencieux si e-mail absent |
| `#notification_admin` | Destinataire = `GMAIL_ACCOUNT` ; sujet présent ; parties HTML + texte ; contient le nom du produit ; retour silencieux si `GMAIL_ACCOUNT` absent |
| `#expedition` | Destinataire = e-mail client ; contient le numéro de suivi ; contient l'URL La Poste ; pas d'URL si numéro absent ; retour silencieux si e-mail absent |

---

### Requêtes HTTP

#### `spec/requests/stripe_payments_spec.rb` — 17 exemples

| Endpoint | Ce qui est testé |
|---|---|
| `POST /fr/stripe_payments` (gate OnlineSales) | Redirige avec alerte si les ventes en ligne sont désactivées |
| `POST /fr/stripe_payments/add_to_cart/:id` | Ajoute l'id en session ; pas de doublon ; flash succès ; refuse les produits non-eshop |
| `DELETE /fr/stripe_payments/remove_from_cart/:id` | Retire l'id de session ; flash info |
| `DELETE /fr/stripe_payments/remove_from_cart_go_back_to_cart/:id` | Retire et redirige vers `/fr/cart` |
| `POST /fr/stripe_payments` (pré-checkout) | CGV non acceptées → alerte ; panier vide → alerte ; produit hors stock → alerte ; race condition boutique → alerte ; `stripe_price_id` absent → alerte |
| `GET /fr/purchase_error` | Redirige vers panier avec alerte annulation |
| `GET /fr/purchase_success` | Redirige vers panier si `session_id` absent ; redirige si Stripe lève `InvalidRequestError` |

#### `spec/requests/webhooks/stripe_spec.rb` — 5 exemples

| Scénario | Code HTTP attendu |
|---|---|
| Secret webhook absent | 503 |
| Signature invalide | 400 |
| `checkout.session.completed` nominal | 200 + appel à `StripeCheckoutFulfillmentService` |
| Erreur interne lors du fulfillment | 500 |
| Événement inconnu (`customer.created`) | 200 (ignoré silencieusement) |

#### `spec/requests/public/pages_spec.rb` — 16 exemples

| Endpoint | Ce qui est testé |
|---|---|
| `GET /fr/cart` | Renvoie 200 ; affiche le montant total ; affiche les noms des produits ; gère les variantes (taille S + M) |
| `POST /fr/cart/transfer_to_cabine` | Transfère `session[:cart]` → `session[:cabine_cart]` ; flash succès ; alerte si panier vide ; alerte si limite 10 produits dépassée |
| `POST /fr/cabine/add_product/:id` | Ajoute en `session[:cabine_cart]` ; pas de doublon ; refuse le 11ᵉ produit |
| `DELETE /fr/cabine/remove_product/:id` | Retire de `session[:cabine_cart]` ; flash info |

---

## Exécuter les tests

### Prérequis

```bash
# Préparer la base de données de test (une seule fois, ou après migration)
bin/rails db:test:prepare
```

### Toute la suite

```bash
bundle exec rspec
```

### Par dossier

```bash
bundle exec rspec spec/models/
bundle exec rspec spec/services/
bundle exec rspec spec/mailers/
bundle exec rspec spec/requests/
```

### Un fichier précis

```bash
bundle exec rspec spec/models/produit_spec.rb
bundle exec rspec spec/models/stripe_payment_item_spec.rb
bundle exec rspec spec/services/shipping_cost_service_spec.rb
bundle exec rspec spec/services/stripe_checkout_fulfillment_service_spec.rb
bundle exec rspec spec/services/stripe_eshop_commande_service_spec.rb
bundle exec rspec spec/mailers/stripe_payment_mailer_spec.rb
bundle exec rspec spec/requests/stripe_payments_spec.rb
bundle exec rspec spec/requests/webhooks/stripe_spec.rb
bundle exec rspec spec/requests/public/pages_spec.rb
```

### Un exemple précis (via numéro de ligne)

```bash
bundle exec rspec spec/services/stripe_checkout_fulfillment_service_spec.rb:57
```

### Options utiles

```bash
# Affichage détaillé (documentation format)
bundle exec rspec --format documentation

# Stopper au premier échec
bundle exec rspec --fail-fast

# Relancer uniquement les tests ayant échoué lors du dernier run
bundle exec rspec --only-failures

# Combiner plusieurs options
bundle exec rspec spec/requests/ --format documentation --fail-fast
```

### Résumé du nombre d'exemples

| Fichier | Exemples |
|---|---|
| `models/produit_spec.rb` | 19 |
| `models/stripe_payment_item_spec.rb` | 5 |
| `services/shipping_cost_service_spec.rb` | 14 |
| `services/stripe_checkout_fulfillment_service_spec.rb` | 17 |
| `services/stripe_eshop_commande_service_spec.rb` | 13 |
| `mailers/stripe_payment_mailer_spec.rb` | 13 |
| `requests/stripe_payments_spec.rb` | 17 |
| `requests/webhooks/stripe_spec.rb` | 5 |
| `requests/public/pages_spec.rb` | 16 |
| **Total** | **119** |
