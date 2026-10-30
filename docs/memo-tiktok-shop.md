# Mémo — TikTok Shop (V1 test)

**Objet :** Tester TikTok Shop comme canal de vente complémentaire avec une vingtaine de produits
**Contexte :** Catalogue Rails existant, import manuel dans TikTok Seller Center
**Principe :** Rails génère le fichier d'import ; tout le reste (commandes, stock, paiements, retours) est manuel
**Statut :** V1 — script d'export implémenté, import test à faire

---

## Ce que fait la V1

| Sujet | Traitement V1 | Où |
|---|---|---|
| Sélection des produits | Automatique, par règles (catégories, 50-200 EUR, disponibles, hors location, hors robes de mariée, hors ensembles) | Script Rails |
| Fichier d'import | Généré à partir des modèles officiels Seller Center (V5.0.2) | Script Rails |
| Publication | Import manuel du fichier | Seller Center |
| Prix et stock sur TikTok | Valeurs du jour de l'export, **figées ensuite** | Seller Center |
| Commandes, expédition, suivi transporteur | Gérés dans TikTok | Seller Center |
| Saisie de la vente dans Rails | Manuelle, à chaque commande TikTok | Admin Rails |

### Générer le fichier

Depuis le poste local, sur la base prod (lecture seule, rien n'est exécuté sur Heroku) :

```bash
cd ~/ror/a1soir
export DATABASE_URL="$(heroku config:get DATABASE_URL -a a1soir-2)?options=-c%20default_transaction_read_only%3Don"
# Vérification du verrou lecture seule : doit afficher "on"
bin/rails runner 'puts ActiveRecord::Base.connection.select_value("SHOW default_transaction_read_only")'

bin/rails runner script/tiktok_shop_export.rb                  # sélection par règles
IDS=12,45,78 bin/rails runner script/tiktok_shop_export.rb     # liste imposée (test)
GROUPER=false bin/rails runner script/tiktok_shop_export.rb    # sans regroupement des déclinaisons

unset DATABASE_URL
```

Sortie : `tmp/tiktok_shop/<modele>_<date>.xlsx` (un fichier par modèle) + rapport dans le terminal : base utilisée, produits retenus, exclus et pourquoi, avertissements.

Double protection : la session PostgreSQL est en lecture seule (`default_transaction_read_only`), et le script s'exécute dans `ActiveRecord::Base.while_preventing_writes`.

Identifiants Seller Center (GPSR) par défaut dans le script : fabricant `6ae3fa3b46e7999c9a4968c8`, personne responsable (l'entreprise) `6ae3f98e76a11eeab816589a`. Surchargeables via `TIKTOK_MANUFACTURER_ID` / `TIKTOK_RP_ID`.

Réglages en tête de [`script/tiktok_shop_export.rb`](../script/tiktok_shop_export.rb) : fourchette de prix, limite, exclusion location, mots exclus, dimensions de colis, correspondance catégories Rails vers TikTok (`MODELES`). Modèles Seller Center : `lib/tiktok_shop/templates/`.

Avec `IDS`, les règles de prix, location, e-shop, mots exclus et limite sont ignorées ; restent obligatoires : image principale, catégorie TikTok trouvée, ni service ni ensemble, disponible aujourd'hui.

Un fichier par modèle, 10 produits TikTok au maximum chacun :

| Modèle | Catégories TikTok | Produits Rails | Prix |
|---|---|---|---|
| `robes.xlsx` | Robes de soirée | catégorie ou type `robe` | 50-200 EUR |
| `accessoires.xlsx` | Ceintures, Gants | type `ceinture`, ou « ceinture » / « gant » dans le nom | 20-200 EUR |
| `hommes.xlsx` | Chemises, Costumes et accessoires | catégorie ou type `chemise` / `costume` | 20-200 EUR |
| `jupons.xlsx` | Jupons gainants | « jupon » dans le nom | 20-200 EUR |

Priorité de classement : type de produit, puis catégorie Rails, puis mots du nom. Les autres accessoires (nœuds, étoles, bijoux...) sont exclus avec le motif « modèle à télécharger » : ajouter le modèle Seller Center correspondant et une entrée dans `MODELES`.

Les modèles téléchargés après la déclaration GPSR (`hommes`, `jupons`) proposent la valeur « Autour D'Un Soir (ID: ...) », reprise telle quelle ; les plus anciens (`robes`, `accessoires`) reçoivent l'identifiant seul.

### Prérequis Seller Center

- Créer le **fabricant** et la **personne responsable** (GPSR), reporter leurs identifiants dans le script.
- Modèles téléchargés : accessoires (gants, ceintures, ensembles d'accessoires) et robes (soirée, invitées). Les **chemises homme** demandent un troisième modèle.
- La marque « Autour D'Un Soir » n'est pas enregistrée : les produits partent en « Aucune marque ».

---

## Ce qui N'EST PAS fait (à connaître avant la première vente)

### Aucune synchronisation automatique

- **Pas de mise à jour du stock TikTok.** Une pièce vendue en boutique ou sur l'e-shop reste en vente sur TikTok.
- **Pas de lecture des commandes TikTok.** Rails ne sait pas qu'une vente TikTok a eu lieu tant qu'elle n'est pas saisie.
- **Pas de mise à jour des prix** après l'export (promotions à gérer dans Seller Center).
- **Pas de rapprochement financier** (commissions, versements TikTok).

### Risque principal : la survente

Beaucoup de produits sont des pièces uniques. Entre une vente ailleurs et la mise à jour manuelle, le même produit peut être vendu deux fois. Une annulation côté vendeur dégrade la santé du compte TikTok.

### Stock dans l'app métier : points d'attention

- Une commande saisie avec **`eshop: true` ne déduit pas le stock** : côté e-shop, seuls les paiements Stripe sont comptés (`Produit#total_vendus_eshop`), et les articles des commandes e-shop sont exclus des ventes boutique (`Produit#total_vendus_boutique`). Une vente TikTok doit donc être saisie comme une **vente boutique** (`eshop: false`).
- **Un retour ne remet pas le produit en stock** : `total_vendus_boutique` ne filtre pas les articles annulés (`annule_at`). Il faut corriger le stock à la main (quantité du produit ou suppression de l'article) et recalculer la disponibilité.
- Les **ensembles Rails** ne sont pas exportés : leur stock calculé vaut toujours 1 et leurs pièces sont choisies à la vente.
- Les **produits proposés aussi en location** sont exclus par défaut : le stock ne tient compte que des locations du jour, pas des réservations futures.

### Analyses

Il n'existe pas de canal « TikTok » : les ventes TikTok apparaîtront dans le **chiffre d'affaires boutique**. Les repérer par le commentaire de la commande.

---

## Procédure manuelle

### À chaque commande TikTok

1. Créer la vente dans Rails, par exemple via **Vente rapide** (vente forcée, `eshop: false`) : articles au prix TikTok.
2. Commentaire de commande : `TikTok Shop — n° <identifiant commande TikTok>`.
3. Paiement : type `prix`, montant brut payé par le client. Moyen : « virement » faute de moyen « TikTok Shop » dans la liste actuelle (noter « TikTok » dans le commentaire du paiement).
4. Vérifier que le produit apparaît bien indisponible dans Rails.
5. Expédier et renseigner le suivi dans Seller Center.

### Après une vente boutique ou e-shop d'un produit publié sur TikTok

- Mettre le stock du produit à **0** dans Seller Center, le jour même.

### Retour ou remboursement TikTok

1. Enregistrer le remboursement dans Rails (avoir / remboursement sur la commande).
2. Si l'article revient en stock : corriger le stock Rails à la main (voir ci-dessus) et remettre le stock dans Seller Center.

### Chaque semaine

- Comparer le stock TikTok des produits publiés avec la disponibilité Rails.
- Noter les versements TikTok (brut, commissions, net) en dehors de Rails pour l'instant.

---

## Évolutions envisagées (si le test est concluant)

1. Colonne `canal` sur les commandes (`boutique`, `eshop`, `tiktok_shop`) : stock et analyses par canal ; moyen de paiement « TikTok Shop ».
2. Prise en compte des articles annulés dans le calcul du stock boutique.
3. Accès API TikTok Shop (Partner Center) : mise à jour automatique du stock et des prix.
4. Lecture des commandes via l'API : commande Rails « à valider » et réservation immédiate du stock (fin de la survente).
5. Rubrique **Admin, TikTok Shop, Opérations** : checklist par commande, frais, versements, retours.
