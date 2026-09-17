# Mémo — Commande rapide

**Objet :** Accélérer la saisie d’une commande boutique en reportant le non-essentiel  
**Contexte :** Admin commandes (hors e-shop)  
**Principe :** Enregistrer vite (articles + paiement), compléter client / dates / événement plus tard  
**Statut :** Cadrage (non implémenté)

---

## Problème

Aujourd’hui, une commande passe souvent par : **client → fiche commande → articles → paiement**.

Beaucoup de champs (identité client, événement, dates, type, commentaires…) freinent l’encaissement ou la prise de commande au comptoir, alors qu’en base seuls `client_id` et `profile_id` sont obligatoires sur `commandes`.

---

## Clarification

**Commande rapide ≠ vente forcée.**  
Le raccourci s’applique à toute commande boutique : location, vente ou mixte. Le type se précise via les articles (`locvente` ligne par ligne), déjà répercuté sur la commande par `Article#after_article_save`.

---

## Solution proposée

**Bouton « Commande rapide »** qui crée une commande pré-remplie :

| Auto / reporté | Saisi tout de suite |
|----------------|---------------------|
| Client technique partagé « Commande rapide » | Articles (produit, qty, prix, loc/vente **par ligne**) |
| Profile = vendeur connecté | Paiement (surtout moyen ; montant aidé) |
| `devis: false` | |
| Type loc/vente/mixte **non forcé** (déduit des articles) | |
| Événement, dates location, commentaires vides | |

**Complétion ultérieure :** changer le client, remplir dates / événement via le formulaire commande existant. Les commandes encore sur le client placeholder = file « à compléter ».

---

## Ce qu’on accélère

| Étape | Aujourd’hui | Commande rapide | Gain |
|-------|-------------|-----------------|------|
| **Client** | Création fiche ou recherche | Client unique « Commande rapide » / « Comptoir » | Évite 1 écran + validations `tel_or_mail` |
| **Profile** | Select manuel | Auto = vendeur connecté | 1 clic en moins |
| **Type commande** | Radio location/vente/mixte à la création | Laissé vide ; déduit des articles | Pas de choix prématuré |
| **Événement** | typeevent + dateevent | Vide | Reportable |
| **Dates location** | debutloc / finloc | Vides au départ | Reportables |
| **Devis / commentaires** | Cases + textes | `devis: false`, vides | Reportable |
| **Statut articles** | `non-retiré` | Inchangé | — |
| **Articles** | Sélection + qty/prix + loc/vente | Conservé | — |
| **Paiement** | type + moyen + montant | Conservé ; aide type `prix`, date du jour, montant = solde | Moins de champs |

---

## Gains estimés (1er passage, 1 article)

Comptage des **champs affichés** dans les formulaires admin.

### Inventaire

- **Client** : 15 champs (language, prenom, nom, propart, intitule, tel, tel2, mail, mail2, adresse, cp, ville, pays, commentaires, contact)
- **Commande** : 10 champs (client, profile, typeevent, dateevent, debutloc, finloc, description, commentaires, devis, type_locvente)
- **Article** : ~4–6 saisies utiles — **non réduit**
- **Paiement** : 5 champs (typepaiement, moyen, montant, commentaires, custom_date)

### Scénarios

| Scénario | Classique | Commande rapide | Réduction |
|----------|-----------|-----------------|-----------|
| **A. Nouveau client** (tous champs affichés) | ~35 / 4 écrans | ~6–7 / 2–3 écrans | **≈ 80–85 %** |
| Hors articles seulement | 30 | 1–2 | **≈ 93–97 %** |
| **B. Client déjà existant** | ~12–15 | ~6–7 | **≈ 40–55 %** |
| **C. Saisie minimale « expérimentée »** | ~8–11 décisions | ~3–4 | **≈ 55–65 %** |

Le gros levier = **sauter client + fiche commande** (~25 champs).

**Nuance :** si le vendeur complète client / dates / événement plus tard, le volume total de données sur le cycle de vie peut se rapprocher du classique. Le bénéfice principal est le **temps jusqu’à commande utilisable / encaissée**, pas une suppression définitive de toutes les infos.

---

## Mise en œuvre technique (rappel)

1. **Client technique partagé** (seed / `find_or_create`), ex. prenom `Commande`, nom `Rapide`, mail interne pour passer `tel_or_mail_present` — pas un client fantôme par commande.
2. **Action** `Admin::CommandesController#create_commande_rapide` (POST) :
   - `client` = placeholder
   - `profile` = vendeur courant
   - `devis: false`
   - ne pas forcer `type_locvente`
   - redirect vers sélection produits (puis paiement)
3. **UI** : bouton sur dashboard / index commandes.
4. **Repérage « à compléter »** : scope sur `client_id` du placeholder + badge show/index.
5. **Paiement** (optionnel) : préremplir `typepaiement: "prix"`, date du jour, montant = solde restant.
6. **Hors scope** : e-shop ; le parcours classique (client d’abord) reste disponible.

### Fichiers clés

- `app/models/client.rb` — `Client.commande_rapide`
- `db/seeds/` — seed du client
- `app/controllers/admin/commandes_controller.rb` + route
- Dashboard / index commandes — bouton
- `app/views/admin/commandes/_commande.html.erb` — badge
- Specs associées

### Point d’attention location

Sans `debutloc` / `finloc`, la disponibilité stock liée aux dates peut être incomplète jusqu’à complétion. Acceptable si le vendeur revient dessus ; éventuellement rappel UI « dates manquantes » si la commande a des lignes location.

---

## Limites

- Analyses / ranking par client : regroupés sous « Commande rapide » jusqu’à réaffectation
- Documents / mails : pas de vrai contact tant que le client n’est pas changé
- Risque de file de commandes « orphelines » si personne ne complète

---

## Next

Valider ce mémo, puis implémenter : client placeholder + action + bouton + badge.
