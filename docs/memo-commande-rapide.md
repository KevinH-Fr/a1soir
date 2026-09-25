# Mémo — Vente rapide

**Objet :** Accélérer la saisie d’une commande boutique en reportant le non-essentiel  
**Contexte :** Admin commandes (hors e-shop)  
**Principe :** Enregistrer vite (articles + paiement), compléter client / dates / événement plus tard  
**Statut :** Implémenté

---

## Problème

Aujourd’hui, une commande passe souvent par : **client → fiche commande → articles → paiement**.

Beaucoup de champs (identité client, événement, dates, type, commentaires…) freinent l’encaissement ou la prise de commande au comptoir, alors qu’en base seuls `client_id` et `profile_id` sont obligatoires sur `commandes`.

---

## Clarification

**Vente rapide = vente forcée** tant que la commande est `a_completer?` (client / profil techniques).  
Création avec `type_locvente: "vente"` ; les articles sont forcés en `locvente: "vente"` ; `Article#after_article_save` ne bascule plus en location/mixte. Une fois le client réel assigné, le comportement loc/vente normal reprend.

---

## Solution

**Bouton « Vente rapide »** (dashboard + index commandes) qui crée une commande pré-remplie :

| Auto / reporté | Saisi tout de suite |
|----------------|---------------------|
| Client technique partagé « Vente Rapide » | Articles (produit, qty, prix — **vente**) |
| Profile technique « Rapide » | Paiement (moyen ; type `prix` + montant solde préremplis) |
| `devis: false`, `type_locvente: "vente"` | |
| Événement, commentaires vides | |

**Complétion ultérieure :** changer le client (select visible à l’édition tant que le client est encore « Vente Rapide ») et le profil, remplir événement via le formulaire commande existant. Badge « Client à compléter » tant que le client technique ; « Événement manquant » tant que type ou date d’événement absents. (« Dates manquantes » ne s’applique plus au parcours rapide, faute de lignes location.)

---

## Mise en œuvre technique

1. **Client technique** : concern `ClientCommandeRapide` → `Client.commande_rapide` (prénom/nom `Vente` / `Rapide`, mail `commande-rapide@example.invalid`).
2. **Profil technique** : concern `ProfileCommandeRapide` → `Profile.commande_rapide` (prénom `Rapide`, comme l’e-shop).
3. **Repérage** : concern `CommandeRapideCompletable` → `a_completer?`, `dates_location_manquantes?`, scope `a_completer`.
4. **Action** `POST Admin::CommandesController#create_commande_rapide` → `type_locvente: "vente"`, `session[:commande]` + redirect sélection produit.
5. **Vente seule** : `Article` force `locvente: "vente"` si `commande.a_completer?` ; `after_article_save` maintient `type_locvente: "vente"`.
6. **UI** : bouton éclair dashboard / index / bloc Accès ; badges show/index ; paiement prérempli si `a_completer?`.
7. **Hors scope** : e-shop ; parcours classique inchangé ; pas de liaison User ↔ Profile ; pas de masquage analyses.

### Fichiers clés

- `app/models/concerns/client_commande_rapide.rb`
- `app/models/concerns/profile_commande_rapide.rb`
- `app/models/concerns/commande_rapide_completable.rb`
- `app/models/article.rb` — force vente + garde `after_article_save`
- `db/seeds/02_profiles.rb`, `db/seeds/06_clients_commandes.rb`
- `app/controllers/admin/commandes_controller.rb` + route
- Dashboard / index commandes — bouton
- `app/views/admin/commandes/_commande.html.erb` — badges
- `app/views/admin/paiement_recus/_paiement_recus.html.erb` — préremplissage
- Specs associées

---

## Limites

- Analyses / ranking : client et CA regroupés sous « Vente Rapide » / profil « Rapide » jusqu’à réaffectation
- Documents / mails : pas de vrai contact tant que le client n’est pas changé
- Risque de file de commandes « orphelines » si personne ne complète
