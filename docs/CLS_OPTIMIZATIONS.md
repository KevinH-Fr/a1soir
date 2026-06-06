# Optimisations CLS — a1soir.com

**Contexte** : CLS actuel ~**0,19** (PageSpeed mobile) / ~**0,23** (Search Console, 51 URLs). Objectif : **≤ 0,10**.

Seul Core Web Vital en échec — LCP (1,5 s) et TTFB (0,7 s) sont déjà bons.

---

## Synthèse des gains estimés

| Optimisation | Portée | Gain CLS estimé | Priorité |
|--------------|--------|-----------------|----------|
| Polices auto-hébergées (`font-display: optional` + fallbacks calibrés) | Site-wide | **−0,05 à −0,10** | 1 |
| Carousel fiche produit (min-height + aspect-ratio + poster vidéo) | Fiches produit | **−0,03 à −0,06** | 2 |
| **Total ciblé (ce plan)** | | **~0,08 à 0,12** après correctifs → objectif **≤ 0,10** | |

> Les gains ne s'additionnent pas toujours linéairement. Mesurer après chaque déploiement.

---

## Audit des polices (vérifié dans le code)

### Source actuelle

| Layout | Google Fonts chargées ? | Rendu effectif |
|--------|-------------------------|----------------|
| **Public** (`app/views/layouts/public.html.erb`) | Oui — 3 familles, `display=swap` | Playfair + Montserrat + Cormorant |
| **Admin** (`app/views/layouts/admin.html.erb`) | **Non** | `body` déclare Playfair mais retombe sur **Arial** (pas de `@font-face`) |

Les polices ne concernent que le site public. L'admin ne doit **pas** recevoir les `@font-face` (sinon son rendu changerait).

### Graisses chargées aujourd'hui vs réellement utilisées

| Famille | CDN actuel | Réellement utilisé | À auto-héberger |
|---------|------------|-------------------|-----------------|
| Playfair Display | 400, 500, 600, 700 | 400 (body), 500, 600, 700, 200 (badge promo — synthétisé) | **400, 500, 600, 700** |
| Montserrat | 300, 400, 500, 600 | 400, 500, 600, 700 (chatbot — 700 synthétisé depuis 600) | **400, 500, 600** (300 inutile) |
| Cormorant Garamond | 400, 500, 600, 700 | 600 (encart festival), 700 (`fw-bold` produit) | **600, 700** minimum ; garder 400–700 parité CDN |

---

### Playfair Display — toutes les pages publiques

**Déclaration globale** : `body` dans `app/assets/stylesheets/application.css` (l.9).

**CSS actif** (`application.css`) :

| Sélecteur | Graisse | Page(s) |
|-----------|---------|---------|
| `body` | 400 | Toutes |
| `.hero-gradient-text` | hérité 400 | CSS présent, pas de vue active trouvée |
| `.discover-main-title` | 700 | CSS présent, pas de vue active trouvée |
| `.scroll-animation-text` | 500 | CSS présent, pas de vue active trouvée |
| `.nav-card-title` | hérité (helper `nav_card_scroll` non utilisé) | — |
| `.seo-hub-section-title` | 500 | `/guides` (hub SEO) |
| `.seo-hub-card-title` | 500 | `/guides` (cartes hub) |
| `.promotion-badge` | 200 | Listings produit (synthétisé) |

**Vues ERB** (style inline `font-family: 'Playfair Display'`) :

| Fichier | Élément |
|---------|---------|
| `categories.html.erb` | h1 |
| `le_concept.html.erb` | h2 |
| `la_boutique/_section_*.html.erb` (5 partials) | h2 / h3 |
| `nos_autres_activites/_section_references.html.erb` | h2 |
| `shared/_section_image_text.html.erb` | h2 (le concept, nos autres activités) |
| `seo_pages/hub.html.erb` | h1 |
| `seo_pages/shared/_hero.html.erb` | h1 |
| `seo_pages/shared/_sections.html.erb` | h2 (×2) |

**Helpers** :

| Fichier | Usage |
|---------|-------|
| `application_helper.rb` | Overlay image + titre (helper image/text) |
| `pages_helper.rb` | `collection_card` — titres cartes collections home |

---

### Montserrat — pas seulement le chatbot

| Sélecteur / fichier | Graisse | Visible quand | Pages |
|---------------------|---------|---------------|-------|
| `.floating-phone-tooltip` (`application.css` l.2884) | 500 | Survol icône téléphone | **Toutes** les pages publiques |
| `.seo-hub-card-subtitle` | 400 | Toujours | `/guides` uniquement |
| `.seo-hub-card-badge` | 400 | Toujours | `/guides` uniquement |
| `.seo-hub-card-cta` | 500 | Toujours | `/guides` uniquement |
| `.floating-chatbot-tooltip` (`chatbot.css`) | 500 | Survol icône chatbot | Si `CHATBOT_ENABLED=true` |
| `.chatbox-header__tagline` | 500 | Panneau chat ouvert | Si chatbot actif |
| `.chatbox-header__action-btn` | 600 | Panneau chat ouvert | Si chatbot actif |
| `.chatbox-msg` | 400 / 700 | Messages chat | Si chatbot actif |

**Conclusion** : Montserrat est requis sur **toutes les pages publiques** à cause du tooltip téléphone, même si le chatbot est désactivé (`CHATBOT_ENABLED` défaut `false`).

---

### Cormorant Garamond — pas seulement l'encart festival

| Fichier | Graisse | Visible quand | Pages |
|---------|---------|---------------|-------|
| `produit.html.erb` l.37 | 700 (`fw-bold`) | Toujours | **Toutes les fiches produit** |
| `_vous_aimerez_aussi.html.erb` | 700 (`fw-bold`) | Si produits similaires | Fiches produit |
| `home_festival_encart.css` `.home-festival-encart__heading` | 600 | Si `FESTIVAL_DE_CANNES_ENABLED=true` (défaut **true**) | Home uniquement |

Fallback déjà prévu pour l'encart festival : `"Cormorant Garamond", "Playfair Display", serif` — mais en prod le CDN charge Cormorant partout, donc l'encart utilise bien Cormorant aujourd'hui.

**Conclusion** : Cormorant est requis sur les **fiches produit** et sur la **home** (si festival activé).

---

## ⚠️ Ce qui changerait le rendu (à ne pas faire)

| Action proposée initialement | Effet visuel |
|------------------------------|--------------|
| Charger Montserrat seulement si `Chatbot.enabled?` | Tooltip téléphone → **Segoe UI** sur toutes les pages |
| Remplacer Montserrat par Segoe UI (tooltip / hub SEO) | Textes hub `/guides` + tooltip **différents** |
| Charger Cormorant seulement sur fiches produit | Encart festival home → **Playfair** au lieu de Cormorant |
| `*= require fonts` dans `application.css` | Admin → **Playfair** au lieu d'Arial actuel |
| `font-display: optional` sans preload ni fallback calibré | Connexion lente → police système au lieu de la webfont |

---

## Stratégie polices — rendu identique + CLS amélioré

### Principe

Changer **comment** les polices sont livrées, pas **où** elles s'appliquent.

1. Auto-héberger les `.woff2` (Fontsource, sous-ensemble latin)
2. `@font-face` avec `font-display: optional` + fallbacks `size-adjust` calibrés (Playfair/Cormorant/Montserrat)
3. Charger les `@font-face` **uniquement dans `public.html.erb`** (fichiers CSS séparés ou un seul `fonts-public.css`) — **pas** dans le `require` Sprockets d'`application.css`
4. Conserver les **3 familles sur toutes les pages publiques** (comme le CDN actuel) pour un rendu strictement identique
5. Preload : `Playfair 400` (body/LCP texte) sur toutes les pages ; ajouter `Cormorant 700` en preload sur fiches produit ; optionnel `Montserrat 500` si le tooltip est critique visuellement
6. Supprimer le lien Google Fonts + `preconnect` fonts.googleapis.com
7. **Ne pas** retirer la graisse Montserrat 300 du scope sans impact — elle n'était déjà pas utilisée

### Fichiers à modifier

| Fichier | Action |
|---------|--------|
| `app/assets/fonts/*.woff2` | Créer |
| `app/assets/stylesheets/fonts-public.css` | `@font-face` + fallbacks |
| `app/views/layouts/public.html.erb` | Preload + `stylesheet_link_tag "fonts-public"` + retirer CDN |
| `config/initializers/assets.rb` | Path fonts + precompile woff2 |
| `app/assets/stylesheets/application.css` | Mettre à jour stack : `"Playfair Display", "Playfair Fallback", Arial` (idem Cormorant/Montserrat où déclaré) |

### Vérification rendu après déploiement

- [ ] Home — body Playfair, encart festival Cormorant (si activé)
- [ ] Fiche produit — h1 Cormorant 700, body Playfair
- [ ] `/fr/guides` — titres Playfair, sous-titres/cartes Montserrat
- [ ] Survol icône téléphone — tooltip Montserrat
- [ ] Chatbot (si activé) — panneau Montserrat
- [ ] Admin — toujours Arial (pas de changement)

---

## 2. Carousel fiche produit — gain estimé : −0,03 à −0,06

### Problème

La classe `.carousel-single` n'a qu'un `max-height: 70vh` sans `min-height` ni `aspect-ratio`. Quand la première slide est une vidéo sans `poster`, la zone s'effondre puis s'agrandit au chargement.

Fichiers concernés :
- `app/assets/stylesheets/application.css` (`.carousel-single`)
- `app/views/public/pages/_carousel.html.erb`
- `app/views/public/pages/produit.html.erb`

À l'inverse, le listing produit (`.carousel-multiple`, 300 px fixe) est déjà correct.

### Solution

```css
.carousel-single .carousel-inner {
  aspect-ratio: 4 / 3;
  min-height: 50vh;
  max-height: 70vh;
  background-color: #f5f5f5;
}
```

- `poster` + `width`/`height` sur la vidéo slide 1
- `preload="metadata"` (pas `auto`)
- `loading: "eager"` + `fetchpriority: "high"` sur l'image active

**Impact rendu** : zone grise placeholder avant chargement média — léger changement visuel transitoire (acceptable pour le CLS), taille finale identique.

---

## Hors scope (impact CLS faible ou nul)

| Élément | Raison |
|---------|--------|
| Bannière cookies | `position-fixed` — overlay, pas de shift in-flow |
| Flash alerts / boutons flottants | `position-fixed` |
| Vidéos la boutique | Below-the-fold, impact moindre |
| Encart période spéciale | Inactif en prod actuellement |
| AOS / scroll-reveal | Transforms — peu d'impact CLS mesuré |

---

## Ordre de déploiement

1. **Polices** (self-host, rendu identique) → mesurer + checklist visuelle ci-dessus
2. **Carousel produit** → mesurer
3. Search Console (mise à jour terrain sous ~28 jours)

## Pages de test

- `/fr` (home + encart festival)
- 2 fiches produit avec vidéo en slide 1
- `/fr/guides` (hub SEO — Montserrat cartes)
- Survol tooltip téléphone
- Admin (vérifier qu'il n'a pas changé)

## Références

- [PageSpeed Insights — a1soir.com/fr mobile](https://pagespeed.web.dev/analysis/https-a1soir-com-fr/ftpdrbfh72?hl=fr&form_factor=mobile)
