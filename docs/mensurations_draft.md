# Mensurations — draft d’implémentation (obsolète)

> Flux actuel : lien unique `/mensurations`, captcha, e-mail, OTP. Voir [`docs/mensurations_evenement_groupe.md`](mensurations_evenement_groupe.md).

Page publique **non référencée**. Accès par invitation admin (e-mail). Pas de fiche client obligatoire pour envoyer le lien.

**Code** : commentaires légers (pourquoi, pas le quoi). Bonnes pratiques Rails, DRY. Réutiliser les patterns existants : `find_existing_for_public_contact`, locale `(:locale)`, `content_for :robots`, `blocLarge` / `card_main_model`, mailers, ActiveStorage `purge`. Pas de gem, pas de helper catalogue pour la photo client.

## Accès

| Qui | Quoi |
|-----|------|
| Admin | Titre **Dimensions** — inviter par mail à donner ses mensurations |
| Client | Lien unique `/mensurations` (puis OTP sur `/fr/m/:token` ou `/en/…`) |
| SEO | Pas de menu public, pas de sitemap, `noindex`, `robots.txt` Disallow `/mensurations` `/fr/m/` `/en/m/` |

Pas de gem à ajouter. Rails suffit : `has_secure_token` (lien, 7 jours), code e-mail 6 chiffres hashé (15 min, ~5 essais), session ~2 h. Modifier / supprimer = **nouveau code**.

## Client

À la 1re sauvegarde, même règle que l’app : `find_existing_for_public_contact(email:, nom:, prenom:, use_prenom_nom_fallback: false)`.

- **mail + nom** (normalisés) → rattacher, ne pas écraser la fiche
- sinon → **créer** le client

## Tables

**Invitation** (en **base**, pas en RAM) : email, token URL, expires_at, template (`homme`/`femme`), locale, prenom/nom optionnels, otp_*, status, client optionnel. Tu ne mémorises pas le token : il est sur la ligne, le mail contient le lien.

**Mensuration** : `belongs_to` invitation + client (après save), JSON `measurements`, `has_one_attached :photo_pied`. Un client = une fiche. Admin : destroy + `purge` photo.

## Champs (extraits des PDF, non modifiés)

Sources : `docs/formulaire mesures femme.pdf`, `docs/formulaire mesures homme.pdf`, `docs/formulaire mesures homme anglais1.pdf`.

**v1 aussi** : femme **anglais** — mêmes champs que le PDF femme FR, libellés dans `en.yml` (pas de 3e template).

`*` = obligatoire sur le papier. Unités cm sauf tailles vêtement / pointure.

**Identité (les deux)** — mappe vers `Client` à la save (mail + nom), pas dans le JSON mesures :

- date \*, prenom \*, nom \*, adresse, cp \*, ville, telephone \*, email \*, date_evenement

**Femme**

- hauteur \* (sans chaussures)
- taille_robe_marque
- hauteur_talons
- taille_pantalon_jupe_marque
- preference_forme_robe (texte)
- taille_veste_chemisier \*
- taille_soutien_gorge \*

*(Le PDF femme 1 page n’a pas de tours corps numérotés en texte, contrairement à l’homme.)*

**Homme**

- hauteur \* (1)
- tour_cou \* (0)
- coupe_chemise (slim | classique)
- taille_veste \*
- taille_chemise \*
- tour_poitrine \* (2)
- tour_taille \* (3)
- tour_hanches \* (4)
- largeur_epaules \* (5)
- longueur_bras_ext \* (7)
- longueur_jambe_ext (ceinture)
- longueur_jambe_int (entrejambe)
- taille_pantalon_marque
- tour_taille_ceinture
- tour_hanches_pantalon
- pointure (FR / US / UK)

YAML : templates `femme` / `homme`, clés ci-dessus. Illustrations = numéros du papier. i18n fr/en. Slot visuel 2D.

Photo en pied : **en plus** des PDF (demande métier).

**Incohérences entre modèles (papier)**

- Femme = tailles **vêtement** (robe, SG, veste). Homme = **tours corps** (poitrine, taille, hanches, épaules, bras) + vêtement. Pas le même jeu de clés.
- Femme : 1 page, aucun n° de zone. Homme : n° (0)(1)(2)(3)(4)(5)(7) — **pas de (6)** ; page 2 **réutilise** (1)(2)(3)(4) pour d’autres mesures (jambes / pantalon).
- Hauteur : femme **sans chaussures** ; homme sans cette précision.
- Homme a pointure ; femme a **talons**, pas de pointure.
- * : CP et tél obligatoires, adresse et ville non. Date événement jamais *.
- Identité : **prénom** et **nom** séparés (comme `Client`). Le papier les colle ; le formulaire web les sépare. Match : mail + nom.
- Homme EN = **mêmes clés** que homme FR. Papier EN : « City & Country » (FR : ville) ; jambes mal traduites (2× inside) → garder le sens FR. Fautes du PDF EN à corriger dans l’UI.

## Photo

Même stockage qu’un produit (ActiveStorage → Cloudinary). **Pas** le helper public `image/upload`.

- Formulaire : fichier + aperçu **local**. Le client ne relit pas la photo stockée.
- Admin : `GET /admin/mensurations/:id/photo` (session staff) → URL Cloudinary **authenticated signée**, courte. Recharger la fiche = nouveau lien. L’admin n’expire pas.

## Visuel guidé

Silhouette SVG (`public/images/human_body.svg`) + règle qui se déplie sur la zone du champ (`clip` YAML).

Même mapping `clip` : `full`, `neck`, `shoulders`, `chest`, `waist`, `hips`, `arm`, `leg` (`torso` / `feet` si un champ les utilise). **Pas** de mannequin sur les tailles vêtement, pointure, talons, préférence.

## Hors v1

- Deux silhouettes distinctes homme / femme (un seul dessin pour l’instant)
