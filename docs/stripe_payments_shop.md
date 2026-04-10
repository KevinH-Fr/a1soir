# Paiements Stripe — boutique en ligne (A1soir)

Ce document décrit le fonctionnement du parcours d'achat en ligne : panier, Checkout Stripe, enregistrement en base, webhooks, lien avec les commandes magasin et l'admin.

---

## Activer la vente en ligne

Le site n'expose les routes Stripe (panier boutique, checkout, webhooks côté métier) que si le flag est **vrai** au démarrage de l'application.

- **Variable d'environnement** : `ONLINE_SALES_AVAILABLE`
- **Interprétation** : booléen Rails (`true`, `1`, `yes`, etc. sont acceptés via `ActiveModel::Type::Boolean`)
- **Configuration** : [`config/initializers/online_sales.rb`](../config/initializers/online_sales.rb)
- **Code applicatif** : la méthode utilitaire [`OnlineSales.available?`](../app/models/online_sales.rb) reflète `Rails.application.config.x.online_sales_available` — `OnlineSales` est un module Ruby (pas une classe).

Les routes sous `scope locale` qui concernent Stripe ne sont montées que si `Rails.application.config.x.online_sales_available` est vrai ([`config/routes.rb`](../config/routes.rb)). Seule l'action `create` est exposée via `resources :stripe_payments, only: [:create]`.

---

## Variables d'environnement Stripe

| Variable | Rôle |
|----------|------|
| `STRIPE_SECRET_KEY` | Clé secrète API ; utilisée côté serveur ([`config/initializers/stripe.rb`](../config/initializers/stripe.rb)). |
| `STRIPE_PUBLISHABLE_KEY` | Clé publique (si vous l'utilisez côté front ou pour d'autres intégrations). |
| `STRIPE_WEBHOOK_SECRET` | Secret du endpoint webhook pour vérifier la signature des événements Stripe. |
| `ONLINE_SALES_AVAILABLE` | Active ou non l'e-shop (routes + garde-fous). |

Sans `STRIPE_WEBHOOK_SECRET`, le endpoint `POST /webhooks/stripe` répond **503** : configurez le secret dans le Dashboard Stripe pour l'URL publique de votre app (ex. `https://votre-domaine.com/webhooks/stripe`) et l'événement **`checkout.session.completed`**.

---

## Parcours côté client

1. **Panier** : les IDs des produits sont stockés en session (`session[:cart]`). Le panier est chargé dans [`Public::ApplicationController#load_cart`](../app/controllers/public/application_controller.rb).
2. **Éligibilité d'un produit** : le bouton « ajouter au panier » boutique n'apparaît que si la vente en ligne est active **et** que le produit a `eshop: true` **et** un `stripe_price_id` (vues produit / grille).
3. **Ajout au panier** : [`StripePaymentsController#add_to_cart`](../app/controllers/public/stripe_payments_controller.rb) refuse les produits sans e-shop ou sans prix Stripe.
4. **Page panier** : [`pages#cart`](../app/controllers/public/pages_controller.rb) + vue panier ; le bouton « Passer au paiement » envoie un **POST** vers `stripe_payments` (`create`).
5. **Avant Checkout** : `create` vérifie que le panier n'est pas vide et que **chaque** ligne a `eshop`, `stripe_price_id` et `today_availability` à `true`. Sinon redirection vers le panier avec message d'alerte.
6. **Session Checkout** : création d'une `Stripe::Checkout::Session` en mode `payment`, une ligne par article du panier, via [`Produit#to_builder`](../app/models/produit.rb) (`price` = `stripe_price_id`, `quantity` = 1). Les métadonnées incluent la locale et la liste des IDs produits du panier.
7. **Après paiement réussi** : Stripe redirige vers `/{locale}/purchase_success?session_id=…` (URL construite avec `request.base_url` + `purchase_success_path(locale: …)` pour éviter de concaténer après `root_url`, qui peut contenir `?locale=…` et produire une URL invalide).
8. **Page de statut** : après traitement, redirection vers `status/:id` (récapitulatif local du paiement).

Annulation côté utilisateur sur Checkout : redirection vers `purchase_error`, puis retour au panier.

---

## Enregistrement du paiement (source de vérité : Stripe)

La logique métier est centralisée dans [`StripeCheckoutFulfillmentService`](../app/services/stripe_checkout_fulfillment_service.rb).

- Elle ne traite que les sessions avec **`payment_status == "paid"`**.
- **Idempotence** : si un `StripePayment` existe déjà pour le même `stripe_checkout_session_id` ou le même `payment_intent`, aucune double création de lignes. La garantie repose sur l'index unique en base (`stripe_checkout_session_id`) et un `SELECT ... FOR UPDATE` dans la transaction principale.
- **Lignes commande** : les `StripePaymentItem` sont créées à partir des **line items Stripe** (prix Stripe → produit local par `Produit.find_by(stripe_price_id: …)`), pas à partir du panier session. Cela aligne le montant et les articles sur ce qui a réellement été payé.
- Champs utiles sur [`StripePayment`](../app/models/stripe_payment.rb) : entre autres `stripe_checkout_session_id`, `stripe_payment_id` (PaymentIntent), `amount`, `currency`, `status`, `customer_email`, lien optionnel vers `commande`.

Deux chemins peuvent appeler le même service :

1. **GET `purchase_success`** : le navigateur revient de Stripe avec `session_id` ; le contrôleur récupère la session via l'API Stripe puis appelle `fulfill!`.
2. **Webhook** `POST /webhooks/stripe` : pour l'événement `checkout.session.completed`, le contrôleur recharge la session avec expansion des line items puis appelle `fulfill!` ([`Webhooks::StripeController`](../app/controllers/webhooks/stripe_controller.rb)).

En production, le **webhook** assure l'enregistrement même si l'utilisateur ferme l'onglet avant le redirect.

---

## Emails après paiement (client + admin)

Lors du **premier** enregistrement réussi d'un paiement (`created: true` dans le résultat du service), [`StripeCheckoutFulfillmentService#enqueue_confirmation!`](../app/services/stripe_checkout_fulfillment_service.rb) met en file un ou deux emails via [`StripePaymentMailer`](../app/mailers/stripe_payment_mailer.rb) :

- **Client** — [`#confirmation`](../app/mailers/stripe_payment_mailer.rb) : envoyé si `customer_email` est renseigné sur le paiement (email saisi côté Stripe Checkout). Langue : préférence du client lié à la commande si disponible, sinon français. Chaque ligne affiche l’image du produit (si `image1` est attachée), le nom, la quantité et un lien vers la fiche produit sur le site public (comme le mail cabine d’essayage).
- **Admin** — [`#notification_admin`](../app/mailers/stripe_payment_mailer.rb) : envoyé si la variable d'environnement `GMAIL_ACCOUNT` est définie (même adresse que les notifications contact / demande de RDV). Contenu : email client, montant, lignes avec image + lien produit, référence de commande si présente, et **lien direct vers la fiche commande dans l’admin** lorsque la commande e-shop a été créée. En production, l’hôte du lien admin est lu dans `ADMIN_MAILER_HOST` (défaut `admin.a1soir.com`) ; en développement, `http://admin.lvh.me:3000/...`.

Un horodatage `confirmation_email_sent_at` est posé dès qu'**au moins un** de ces envois a été mis en file, ce qui évite les doublons (webhook + redirect, ou rejeu). L'idempotence de l'enregistrement du paiement reste assurée en amont dans la transaction du service.

---

## Lien avec les commandes magasin (`Commande`)

[`StripeEshopCommandeService`](../app/services/stripe_eshop_commande_service.rb) est appelé depuis le service de fulfillment après création des lignes, si le paiement est nouveau :

- Création ou réutilisation d'un **Client** à partir de l'email Stripe.
- Création d'une **Commande** vente (`type_locvente: "vente"`) rattachée au profil vendeur **e-shop** : [`Profile.for_eshop_commandes`](../app/models/profile.rb) (profil dont le `nom` correspond à `eshop`, insensible à la casse ; s'il n'existe pas, création avec `prenom` « E-shop » et `nom` `eshop`).
- Les **nouveaux clients** créés depuis le checkout ont l'intitulé **`Madame/Monsieur`** ([`Client::ESHOP_DEFAULT_INTITULE`](../app/models/client.rb)), faute de civilité connue côté Stripe.
- Création d'**Articles** en `locvente: "vente"` avec quantités et montants dérivés des `StripePaymentItem`.
- Mise à jour de `stripe_payment.commande_id`.

Si aucun **email client** n'est disponible, la commande n'est pas créée ; un avertissement est écrit dans les logs. Un profil e-shop est toujours obtenu ou créé automatiquement.

---

## Catalogue et synchronisation des produits Stripe (admin)

Quand `OnlineSales.available?` est vrai, les actions pertinentes du [`Admin::ProduitsController`](../app/controllers/admin/produits_controller.rb) appellent [`StripeProductService`](../app/services/stripe_product_service.rb) pour :

- créer un **produit** et un **prix** Stripe lors de la création / duplication de produit ;
- mettre à jour nom / description, et **créer un nouveau prix** (désactivation de l'ancien) si le `prixvente` change.

Les identifiants Stripe sont stockés sur `produits` : `stripe_product_id`, `stripe_price_id`.

### Recréer produits et prix (console Rails)

Sur un **nouveau compte Stripe** ou après changement de clés, les anciens `prod_…` / `price_…` ne sont plus valides. Avec `STRIPE_SECRET_KEY` pointant vers le bon compte, exécuter dans **`bin/rails console`** :

**Recréation complète** pour les produits **e-shop**, **disponibles aujourd’hui** (`today_availability: true`) et avec **`prixvente` > 0** (les IDs en base sont effacés puis `StripeProductService` recrée Product + Price) :

```ruby
scope = Produit.where(eshop: true, today_availability: true)
               .where("prixvente IS NOT NULL AND prixvente > 0")

scope.update_all(stripe_product_id: nil, stripe_price_id: nil)

scope.find_each do |p|
  StripeProductService.new(p.reload).create_product_and_price
  puts "#{p.id} → #{p.reload.stripe_price_id}"
end

Le service pose une métadonnée `produit_id` sur le Product Stripe et n’envoie la description que si elle est renseignée ([`StripeProductService`](../app/services/stripe_product_service.rb)).

---

## Stock et disponibilité

Les ventes e-shop comptent dans la logique de stock via les `StripePaymentItem` liés à un paiement au statut `paid` (ex. [`Produit#total_vendus_eshop`](../app/models/produit.rb), inventaire CSV). Des callbacks `after_commit` sur [`StripePaymentItem`](../app/models/stripe_payment_item.rb) (on: create) et [`StripePayment`](../app/models/stripe_payment.rb) (on: update) déclenchent `update_today_availability` sur les produits concernés lorsque le paiement est payé. L'utilisation de `after_commit` garantit que les mises à jour de disponibilité n'ont lieu qu'une fois la transaction principale commitée.

---

## Interface d'administration

- Liste des paiements Stripe (index admin uniquement) : [`Admin::StripePaymentsController#index`](../app/controllers/admin/stripe_payments_controller.rb), entrée « Paiements e-shop » dans le bloc Accès du tableau de bord admin. Le détail d’un paiement est affiché sur la **fiche commande** associée lorsqu’elle existe ; la liste propose un lien direct vers cette commande.

---

## Webhook Stripe

Le controller [`Webhooks::StripeController`](../app/controllers/webhooks/stripe_controller.rb) hérite de `ActionController::API` (pas `ActionController::Base`) : pas de session, pas de CSRF, pas de rendu de vues — adapté à un endpoint machine-à-machine recevant du JSON brut signé par Stripe. La route `POST /webhooks/stripe` est montée **en dehors** du `scope locale` et du bloc conditionnel `online_sales_available`, afin d'être toujours disponible.

---

## Limites et points d'attention

- **Quantités** : le panier session est une liste d'IDs (un exemplaire par produit) ; `to_builder` envoie `quantity: 1` par ligne. Pas de multi-quantité par produit dans le panier actuel.
- **Fiche produit** : l'URL directe d'un produit hors e-shop peut toujours être consultée ; seuls les produits éligibles affichent le bouton d'achat en ligne.
- **Commande auto** : dépend d'au moins un `Profile` en base et d'un email collecté par Stripe Checkout.
- **`belongs_to :produit` sur `StripePayment`** : conservé pour compatibilité ascendante — à supprimer par migration lorsque la colonne ne sera plus utilisée.
- **Tests** : une partie des specs Stripe vit sous `spec/services`, `spec/requests/webhooks`, etc. ; la suite RSpec complète du projet peut avoir d'autres fichiers en erreur indépendants de Stripe.

---

## Fichiers principaux (référence rapide)

| Sujet | Fichier |
|------|---------|
| Routes publiques Stripe + condition e-shop | `config/routes.rb` |
| Webhook global | `config/routes.rb` (`post /webhooks/stripe`) |
| Contrôleur checkout / panier / success | `app/controllers/public/stripe_payments_controller.rb` |
| Fulfillment idempotent | `app/services/stripe_checkout_fulfillment_service.rb` |
| Commande + articles magasin | `app/services/stripe_eshop_commande_service.rb` |
| Webhook Stripe | `app/controllers/webhooks/stripe_controller.rb` |
| Modèles | `app/models/stripe_payment.rb`, `app/models/stripe_payment_item.rb` |
| Sync catalogue Stripe | `app/services/stripe_product_service.rb` |
| Clés API | `config/initializers/stripe.rb` |
| Flag e-shop | `config/initializers/online_sales.rb` |
