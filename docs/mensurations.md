# Dimensions (mensurations)

Lien public unique `/mensurations` (copiable depuis l’admin **Dimensions**). Pas de menu, pas de sitemap, `noindex` + `Disallow` robots.

## Flux

1. Saisie e-mail + captcha → envoi d’un **code OTP** par mail  
2. Vérification du code → session sur `/m/:token` (FR/EN)  
3. Choix femme / homme → formulaire en sections (identité, tailles, corps, photo)  
4. Fiche visible en admin **Dimensions** et sur le compte client  

Langue et template restent modifiables après envoi. On peut revenir plus tard modifier **sa** fiche.

## Formulaire

Champs définis dans `config/mensuration_fields.yml` (`clip` = zone silhouette). Photo en pied optionnelle.

## Silhouette animée

Six SVG intacts :

- `public/images/mensurations_{femme|homme}_{face|profil|dos}.svg`

Le guide (`measure-guide`) charge la vue selon le `clip` YAML, puis active le groupe `#measure-*` (classe `is-active`). Mapping JS : `app/javascript/mensuration/figure_assets.js`. Fond carte / papier SVG harmonisé : `#f3ebe0`. Guides = règles pointillées (pas d’anneaux).

**TODO** : alléger les SVG (~2 Mo chacun, PNG embarqué en base64) — extraction PNG + overlay SVG plus tard.
