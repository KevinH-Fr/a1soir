# Brief éditorial — pages SEO

Checklist pour enrichir les pages du registre `config/seo_pages.yml`. Contenu dans `config/locales/seo_pages.fr.yml` et `config/locales/seo_pages.en.yml`.

## Ton

- Conseillère boutique à Cannes, chaleureuse et précise — pas blog mariage générique.
- Tutoiement indirect (« vous ») cohérent avec le site public.
- Phrases courtes, paragraphes aérés, listes HTML si utile (`<ul><li>`).

## Faits métier (ne jamais contredire)

| Sujet | Règle |
|-------|--------|
| Robes de mariée | **Vente uniquement** — pas de location |
| Tenues de soirée, smokings, costumes | **Location ou vente** en boutique |
| RDV | Fortement recommandé (essayage, retouches) |
| Location | 4 jours standard (retrait J-2, retour J+2) — distinct de l'essayage/retouches (avant retrait) |
| Réservation location | En boutique, acompte 30 % (aligné FAQ / CGL) |
| Adresse | 29 boulevard Carnot, 06400 Cannes |
| Fondation | Depuis **1980** |

## Géo

- Mention Nice / Antibes / Monaco / Côte d'Azur : **1 à 2 fois par page**, pas dans chaque section.
- Une seule boutique à Cannes — zone desservie, pas d'adresses fictives ailleurs.

## Histoire et expertise

- Mélanger **culture mode** (évolution d'un style) et **vécu boutique** (cabine, retouches, Festival).
- Sources : `public.pages.la_boutique.universe`, `team`, `carousel` dans `config/locales/fr.yml`.
- Ne pas copier-coller mot pour mot ; adapter au sujet de la page.

## Structure par page

| Bloc YAML | Cible |
|-----------|--------|
| `intro_html` | 2 paragraphes (~120–180 mots) |
| `sections.*` | 3–5 sections, 2–3 paragraphes chacune |
| `sections.histoire` ou `expertise` | 1 section sur pages prioritaires |
| `faq` | 3–5 paires `qN` (question + answer_html) |
| `meta_tags.pages.<meta_key>` | Title + description 155–160 car. |

## Règle FR / EN

1. **Une page = deux fichiers** mis à jour ensemble.
2. Mêmes clés : sections, faq q1…qN, meta.
3. EN : adaptation (« French Riviera », « since 1980 »), pas traduction littérale.
4. Liens internes dans `body_html` : chemins `/fr/...` et `/en/...` selon locale (ou texte sans lien si pas de route stable).

## Liens internes suggérés

- Hub guides : `/fr/guides`, `/en/guides`
- Landings : `/fr/robe-de-mariee-cannes`, `/en/robe-de-mariee-cannes`
- Guides : `/fr/guides/comment-choisir-sa-robe-de-mariee`, etc.
- Boutique : `/fr/la-boutique`, `/en/la-boutique` (vérifier route réelle)

## Pages prioritaires (phase 1)

1. `robe_de_mariee_cannes`
2. `comment_choisir_sa_robe_de_mariee`
3. `robe_de_mariee_boheme`
4. `location_smoking_costume_cannes`

## Lots suivants (phase 2)

- **A** : essayage, costume mariage
- **B** : morphologie, smoking ou costume
- **C** : invitée, gala
- **D** : achat/location, chaussures accessoires

## Hors scope contenu

- Inventer des prix ou chiffres non validés
- Promettre location robes mariée
- Contenu dupliqué identique sur 12 pages

## Vidéo (reporté)

Intégration vidéo optionnelle (partial + `includes: video` dans le YAML) : à activer lorsqu'une URL Cloudinary ou YouTube boutique est disponible. Cible prioritaire : `robe-de-mariee-cannes` ou `essayage-robe-de-mariee-cannes`.
