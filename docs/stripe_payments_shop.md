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
7. **Après paiement réussi** : Stripe redirige vers `/{locale}/purchase_success?session_id=…` (URL construite avec `request.base_url` + `purchase_success_path(locale: …)` pour éviter de concaténer après `root_url`, qui peut contenir `?locale=…` et produire une URL invalide). Le contrôleur n'accepte ce retour détaillé que si l'ID Checkout correspond à celui stocké en session navigateur au moment de la création (`session[:pending_stripe_checkout_id]`).
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

1. **GET `purchase_success`** : le navigateur revient de Stripe avec `session_id` ; si l'ID ne correspond pas au checkout lié à la session navigateur, l'utilisateur est renvoyé vers l'accueil avec un message générique (sans accès au récap). En cas de correspondance, le contrôleur récupère la session via l'API Stripe puis appelle `fulfill!`.
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
```

Le service pose une métadonnée `produit_id` sur le Product Stripe et n’envoie la description que si elle est renseignée ([`StripeProductService`](../app/services/stripe_product_service.rb)).

### Refresh incrémental (post-bulk)

Après un **bulk** console (milliers de produits sur une plage horaire), des modifs admin peuvent ne pas avoir été poussées vers Stripe si `ONLINE_SALES_AVAILABLE` était `false` (les callbacks du [`Admin::ProduitsController`](../app/controllers/admin/produits_controller.rb) ne s’exécutent pas). Le bulk écrit les IDs via `update_columns` : **`updated_at` ne bouge pas** pendant le bulk ; seules les vraies sauvegardes admin ou les créations font monter `updated_at` / `created_at`.

**Ne pas** réutiliser le script bulk (`update_all(stripe_product_id: nil, …)`). Utiliser `update_product_and_price` sur un périmètre restreint.

**Prérequis** : `STRIPE_SECRET_KEY` sur le bon compte. `OnlineSales.available?` peut rester `false` en console (le service Stripe est appelé directement).

#### Borne `SINCE`

L’app est en **`Europe/Paris`** ([`config/application.rb`](../config/application.rb)) : `Time.zone.parse` = heure **France**, comme dans le Dashboard Stripe.

Reculer **avant** la première création visible dans Stripe (le bulk peut avoir démarré avant l’heure du premier produit affiché, ex. premier `prod_` à 14h56 alors que le script a commencé plus tôt). Tous les produits modifiés ou créés en admin **depuis** `SINCE` sont candidats. Le bulk n’a pas touché `updated_at` (IDs écrits via `update_columns`), donc les ~3000 lignes déjà synchronisées ne remontent pas sauf si `stripe_*` manquant.

```ruby
# Jour J — heure France : 30 à 60 min avant le premier produit Stripe du bulk
SINCE = Time.zone.parse("2026-05-29 14:00:00")

# Ou l’heure exacte du tout premier create Stripe si vous la connaissez, moins une marge :
# SINCE = Time.zone.parse("2026-05-29 13:30:00")
```

#### Étape 1 — Dry-run (lister les candidats)

```ruby
# bin/rails console
# heroku run rails console -a <app>

SINCE = Time.zone.parse("2026-05-29 12:00:00")  # heure France (Europe/Paris), avant le début réel du bulk

puts "Stripe key: #{Stripe.api_key.to_s[0, 12]}..."
puts "SINCE (Paris) : #{SINCE}"

candidates = Produit.where(eshop: true)
  .where("prixvente IS NOT NULL AND prixvente > 0")
  .where(
    "updated_at >= ? OR created_at >= ? OR stripe_product_id IS NULL OR stripe_price_id IS NULL",
    SINCE, SINCE
  )
  .order(:id)

puts "Candidats : #{candidates.count}"
candidates.pluck(:id, :nom, :created_at, :updated_at, :stripe_price_id).each { |r| puts r.inspect }
```

- `stripe_*` NULL → créations ou oublis (sans filtre date).
- `updated_at >= SINCE` → modifs admin post-bulk (nom, description, etc.).
- `created_at >= SINCE` → nouveaux produits.

`today_availability` utilise `update_column` → ne fausse pas `updated_at`.

Un `updated_at` le jour du bulk peut venir d’une **migration / renommage** en masse (pas seulement d’une fiche admin) : le dry-run peut lister des dizaines de lignes déjà OK côté Stripe. D’où l’étape 1b avant de pousser.

#### Étape 1b — Comparer app ↔ Stripe (lecture seule)

Sur le même `candidates` que l’étape 1 (~64 lignes typiques) :

```ruby
gaps = []  # [id, nom, raison]

candidates.find_each do |p|
  if p.stripe_product_id.blank? || p.stripe_price_id.blank?
    gaps << [p.id, p.nom, "ids_manquants_en_base"]
    next
  end

  sp = Stripe::Product.retrieve(p.stripe_product_id)
  unless sp.name == p.nom.to_s
    gaps << [p.id, p.nom, "nom"]
  end
  expected_desc = p.description.present? ? p.description.to_s.truncate(4500) : nil
  unless expected_desc.nil? || sp.description.to_s == expected_desc
    gaps << [p.id, p.nom, "description"]
  end
rescue Stripe::InvalidRequestError
  gaps << [p.id, p.nom, "absent_sur_stripe"]
end

ids_to_sync = gaps.map(&:first).uniq
puts "Écarts : #{gaps.size} ligne(s), #{ids_to_sync.size} produit(s) à synchroniser"
gaps.each { |r| puts r.inspect }

# Déjà alignés (optionnel)
aligned = candidates.where.not(id: ids_to_sync).pluck(:id, :nom)
puts "Déjà OK (nom + description) : #{aligned.size}"
```

#### Étape 2 — Synchroniser (create ou update selon le besoin)

**Option A — uniquement les écarts** (recommandé après 1b) :

```ruby
to_sync = Produit.where(id: ids_to_sync).order(:id)

ok = 0
errors = []

to_sync.find_each do |p|
  StripeProductService.new(p.reload).update_product_and_price
  p.reload
  puts "OK ##{p.id} #{p.nom} → #{p.stripe_price_id}"
  ok += 1
rescue StandardError => e
  puts "ERR ##{p.id} : #{e.message}"
  errors << p.id
end

puts "Refresh : #{ok}/#{to_sync.count} OK, #{errors.size} erreur(s)"
```

**Option B — tout le lot `candidates`** (si vous préférez forcer sans audit, ex. &lt; 100 lignes) :

```ruby
ok = 0
errors = []

candidates.find_each do |p|
  StripeProductService.new(p.reload).update_product_and_price
  p.reload
  puts "OK ##{p.id} #{p.nom} → #{p.stripe_price_id}"
  ok += 1
rescue StandardError => e
  puts "ERR ##{p.id} : #{e.message}"
  errors << p.id
end

puts "Refresh : #{ok}/#{candidates.count} OK, #{errors.size} erreur(s)"
```

Par produit, [`StripeProductService#update_product_and_price`](../app/services/stripe_product_service.rb) :

- IDs Stripe **absents** → `create_product_and_price`.
- IDs **présents** → `Stripe::Product.update` (nom, description, images) ; le `Price` n’est recréé que si `prixvente` a changé sur le dernier `save` admin.
- IDs **invalides** sur le compte courant → recréation automatique (rescue existant).

**Attention** : en refresh massif, `images: []` peut effacer les images Stripe si le produit n’a pas d’`image1` attachée (même comportement qu’en admin).

#### Étape 3 — Vérification

```ruby
still = candidates.where("stripe_product_id IS NULL OR stripe_price_id IS NULL")
puts still.count.zero? ? "OK" : still.pluck(:id, :nom)
```

Puis activer `ONLINE_SALES_AVAILABLE=true` en prod pour que les prochains saves admin restent synchronisés sans script.

#### Audit ponctuel (optionnel)

**Ne pas** lancer en routine sur tout le catalogue (~3000 appels `Product.retrieve`, rate limits). Utile une seule fois si le dry-run est suspect ou en cas de doute sur la fin du bulk. Script **lecture seule** ; en cas d’écarts, lancer l’étape 2 uniquement sur les IDs concernés.

```ruby
mismatches = []
Produit.where(eshop: true)
  .where("prixvente IS NOT NULL AND prixvente > 0")
  .where.not(stripe_product_id: nil)
  .find_each do |p|
    sp = Stripe::Product.retrieve(p.stripe_product_id)
    name_ok = sp.name == p.nom.to_s
    expected_desc = p.description.present? ? p.description.to_s.truncate(4500) : nil
    desc_ok = expected_desc.nil? || sp.description.to_s == expected_desc
    mismatches << [p.id, p.nom] unless name_ok && desc_ok
  rescue Stripe::InvalidRequestError
    mismatches << [p.id, p.nom, "missing_on_stripe"]
  end
puts "Écarts : #{mismatches.size}"
mismatches.first(20).each { |r| puts r.inspect }
```

La comparaison stricte nom/description est fragile (description tronquée à 4500 car., description vide en base mais encore présente sur Stripe). Le checkout repose surtout sur `stripe_price_id`.

### Audit catalogue e-shop ↔ Stripe (existence, lecture seule)

Vérifie que **chaque** produit e-shop éligible au checkout a un `stripe_product_id` et un `stripe_price_id` en base, et que ces objets **existent** sur le compte Stripe courant (`STRIPE_SECRET_KEY`). **Aucune écriture** (pas de `StripeProductService`, pas de `create` / `update`).

Comptez ~2 appels API par produit (`Product.retrieve` + `Price.retrieve`) — sur ~3000 lignes, prévoir quelques minutes et respecter les rate limits Stripe.

```ruby
# bin/rails console
# heroku run rails console -a <app>

puts "Stripe key: #{Stripe.api_key.to_s[0, 12]}..."

scope = Produit.where(eshop: true)
               .where("prixvente IS NOT NULL AND prixvente > 0")
               .order(:id)

missing_ids_db   = []  # pas d'ID en base
product_missing  = []  # prod_ introuvable
price_missing    = []  # price_ introuvable
price_orphan     = []  # price existe mais rattaché à un autre Product
inactive         = []  # product ou price désactivé (info)
api_errors       = []  # autre erreur Stripe
ok_count         = 0
total            = scope.count

scope.find_each.with_index do |p, i|
  puts "… #{i + 1}/#{total}" if total.positive? && ((i + 1) % 200).zero?

  if p.stripe_product_id.blank? || p.stripe_price_id.blank?
    missing_ids_db << [p.id, p.nom, p.stripe_product_id, p.stripe_price_id]
    next
  end

  begin
    sp = Stripe::Product.retrieve(p.stripe_product_id)
    inactive << [p.id, p.nom, "product_inactive"] if sp.active == false
  rescue Stripe::InvalidRequestError => e
    product_missing << [p.id, p.nom, p.stripe_product_id, e.message]
    next
  end

  begin
    pr = Stripe::Price.retrieve(p.stripe_price_id)
    inactive << [p.id, p.nom, "price_inactive"] if pr.active == false
    if pr.product != p.stripe_product_id
      price_orphan << [p.id, p.nom, p.stripe_price_id, "price→#{pr.product}"]
    end
  rescue Stripe::InvalidRequestError => e
    price_missing << [p.id, p.nom, p.stripe_price_id, e.message]
    next
  end

  ok_count += 1
rescue StandardError => e
  api_errors << [p.id, p.nom, e.class, e.message]
end

puts "\n--- Rapport (lecture seule) ---"
puts "Catalogue e-shop (prixvente > 0) : #{total}"
puts "OK (product + price existants)   : #{ok_count}"
puts "Sans IDs en base                 : #{missing_ids_db.size}"
puts "Product introuvable sur Stripe   : #{product_missing.size}"
puts "Price introuvable sur Stripe     : #{price_missing.size}"
puts "Price rattaché à autre Product   : #{price_orphan.size}"
puts "Product/Price inactifs (info)    : #{inactive.size}"
puts "Autres erreurs                   : #{api_errors.size}"

[[missing_ids_db, "Sans IDs en base"],
 [product_missing, "Product introuvable"],
 [price_missing, "Price introuvable"],
 [price_orphan, "Price orphelin"],
 [inactive, "Inactifs (info)"],
 [api_errors, "Autres erreurs"]].each do |list, label|
  next if list.empty?

  puts "\n#{label} (#{list.size}) :"
  list.first(30).each { |r| puts "  #{r.inspect}" }
  puts "  … et #{list.size - 30} de plus" if list.size > 30
end

puts "\nTerminé — rien n'a été modifié."
```

En cas d’anomalies : corriger en base ou lancer le [refresh incrémental](#refresh-incrémental-post-bulk) / recréation ciblée — pas ce script.

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
- **Protection `purchase_success`** : l'accès au récapitulatif détaillé est limité au navigateur ayant lancé le Checkout (binding session). Sur un autre appareil, la commande reste traitée par webhook et l'utilisateur reçoit son email de confirmation.
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


---'


ToDo:

ok - modif du mail avec info livraison à venir par lequipe
ok - quid webhook ? local et prod ? prod seulement avec le endpoint etc
ok - quid protection purchase success ?


reprendre : 

mode prod avec cha :
ok - activer espace de prod avec toutes les infos
- var env de prod et espace de prod dans stripe : 

ok - supprimer les cles existantes
ok - créer des cles restreintes
ok - webhook en prod

- créer les produits et prices dans stripe pour la partie prod : script ci dessous
- tester avec cha sur le site

test achat eshop : 4291

# bin/rails console
# heroku run rails console -a <app>

# :all = tous les produits eshop | :first = les N premiers (ordre id)
MODE  = :all
LIMIT = 10   # utilisé seulement si MODE = :first

puts "Stripe key: #{Stripe.api_key.to_s[0, 12]}..."

scope = Produit.where(eshop: true)
               .where("prixvente IS NOT NULL AND prixvente > 0")
               .order(:id)

scope = scope.limit(LIMIT) if MODE == :first

puts "Sync : #{scope.count} produit(s)"

# Reset IDs Stripe du lot (nouvel env / nouveau compte)
scope.update_all(stripe_product_id: nil, stripe_price_id: nil)

ok = 0
errors = []

scope.find_each do |p|
  StripeProductService.new(p.reload).create_product_and_price
  p.reload
  puts "OK ##{p.id} #{p.nom} → #{p.stripe_price_id}"
  ok += 1
rescue StandardError => e
  puts "ERR ##{p.id} : #{e.message}"
  errors << p.id
end

puts "Lot : #{ok}/#{scope.count} OK, #{errors.size} erreur(s)"

# Rapport global : produits eshop encore incomplets
missing = Produit.where(eshop: true)
                 .where("prixvente IS NOT NULL AND prixvente > 0")
                 .where("stripe_product_id IS NULL OR stripe_price_id IS NULL")

if missing.none?
  puts "OK — tous les produits eshop ont leurs IDs Stripe."
else
  puts "#{missing.count} produit(s) eshop sans IDs Stripe :"
  missing.pluck(:id, :nom).each { |id, nom| puts "  ##{id} #{nom}" }
end







dans doc pdf commande eshop:
- avoir une ligne dans les articles avec le cout de livraison (montant payé dans stripe)
- avoir une ligne paiement recu stripe
- ne pas avoir la ligne de solde
- enlever servi par eshop et statut non retiré en haut à droite sur paiement eshop 

ok

- bouton remboursement la commande eshop : (ca la passe en devis (verif stock bien corrigé), ca ajoute un remboursemetn du montant du paiement stripe, ajoute un badge qui dit commande remboursée et une alerte visible sur la page web qui dit attention remboursement a faire depuis stripe)
verif document facture conforme avec le remboursement

ok 



todo:

ok - refresh incrémental post-bulk (voir section « Refresh incrémental » ci-dessus)

avant 3320

apres idem avec 9 modifs