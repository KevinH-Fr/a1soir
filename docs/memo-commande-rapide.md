# Mémo — Commande rapide

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

**Commande rapide ≠ vente forcée.**  
Le raccourci s’applique à toute commande boutique : location, vente ou mixte. Le type se précise via les articles (`locvente` ligne par ligne), déjà répercuté sur la commande par `Article#after_article_save`.

---

## Solution

**Bouton « Commande rapide »** (dashboard + index commandes) qui crée une commande pré-remplie :

| Auto / reporté | Saisi tout de suite |
|----------------|---------------------|
| Client technique partagé « Commande Rapide » | Articles (produit, qty, prix, loc/vente **par ligne**) |
| Profile technique « Rapide » | Paiement (moyen ; type `prix` + montant solde préremplis) |
| `devis: false` | |
| Type loc/vente/mixte **non forcé** (déduit des articles) | |
| Événement, dates location, commentaires vides | |

**Complétion ultérieure :** changer le client (select visible à l’édition tant que le client est encore « Commande Rapide ») et le profil, remplir dates / événement via le formulaire commande existant. Badge « Client à compléter » tant que le client technique ; « Dates manquantes » si ligne location sans dates ; « Événement manquant » tant que type ou date d’événement absents.

---

## Clics gagnés (implémenté)

Un clic = action pointeur. Hors article (identique des deux côtés). Objectif = temps jusqu’à encaissement.

- **8 clics** si le client est déjà dans la liste du dashboard (13 → 5 hors article).
- **9 clics** pour un nouveau client, ou via « + » Commandes (14 → 5).
- Dont **5–6** (saut client + fiche commande + select profil + entrée sélection produit) et **3** (paiement prérempli type + montant).

---

## Mise en œuvre technique

1. **Client technique** : concern `ClientCommandeRapide` → `Client.commande_rapide` (prénom/nom `Commande` / `Rapide`, mail `commande-rapide@example.invalid`).
2. **Profil technique** : concern `ProfileCommandeRapide` → `Profile.commande_rapide` (prénom `Rapide`, comme l’e-shop).
3. **Repérage** : concern `CommandeRapideCompletable` → `a_completer?`, `dates_location_manquantes?`, scope `a_completer`.
4. **Action** `POST Admin::CommandesController#create_commande_rapide` → `session[:commande]` + redirect sélection produit.
5. **UI** : bouton éclair dashboard / index / bloc Accès ; badges show/index ; paiement prérempli si `a_completer?`.
6. **Hors scope** : e-shop ; parcours classique inchangé ; pas de liaison User ↔ Profile ; pas de masquage analyses.

### Fichiers clés

- `app/models/concerns/client_commande_rapide.rb`
- `app/models/concerns/profile_commande_rapide.rb`
- `app/models/concerns/commande_rapide_completable.rb`
- `db/seeds/02_profiles.rb`, `db/seeds/06_clients_commandes.rb`
- `app/controllers/admin/commandes_controller.rb` + route
- Dashboard / index commandes — bouton
- `app/views/admin/commandes/_commande.html.erb` — badges
- `app/views/admin/paiement_recus/_paiement_recus.html.erb` — préremplissage
- Specs associées

### Point d’attention location

Sans `debutloc` / `finloc`, la disponibilité stock liée aux dates peut être incomplète jusqu’à complétion. Badge « Dates manquantes » si la commande a des lignes location.

---

## Limites

- Analyses / ranking : client et CA regroupés sous « Commande Rapide » / profil « Rapide » jusqu’à réaffectation
- Documents / mails : pas de vrai contact tant que le client n’est pas changé
- Risque de file de commandes « orphelines » si personne ne complète
