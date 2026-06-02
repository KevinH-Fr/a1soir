# Pages SEO — rôle et implémentation

Documentation concise du système de pages SEO d’Autour D’Un Soir (guides + landing pages locales).

## Rôle

Ces pages ciblent des requêtes Google **informatives** (guides) et **locales** (Cannes et Riviera) pour :

- améliorer le référencement naturel ;
- orienter vers la boutique (RDV, produits, carte) ;
- structurer le contenu éditorial sans dupliquer la logique métier du site.

**Principe :** une seule boutique à Cannes. Les pages locales et les mentions géo (Nice, Monaco…) décrivent une **zone desservie**, pas des adresses fictives.

---

## URLs

| Type | Exemple FR | Exemple EN |
|------|------------|------------|
| Hub | `/fr/guides` | `/en/guides` |
| Guide | `/fr/guides/robe-de-mariee-boheme` | `/en/guides/robe-de-mariee-boheme` |
| Landing locale | `/fr/robe-de-mariee-cannes` | `/en/robe-de-mariee-cannes` |

- Préfixe `/fr` ou `/en` : contenu traduit, **slug identique** dans les deux langues.
- Les guides sont sous `/guides/:slug` ; les landings locales à la racine locale (`/:slug`).

---

## Architecture

```
config/seo_pages.yml          → registre (slug, type, filtres, images, liens…)
config/locales/seo_pages.*.yml → textes + meta tags (FR / EN)

SeoPages::Registry            → charge le YAML, sitemap, hub, i18n_key
SeoPages::ProductScope        → produits liés (catégories)
Constraints::SeoPageSlug      → route locale sans conflit avec /faq, /contact…

Public::SeoPagesController    → hub + show
SeoPagesHelper                → traductions, chemins, images, hub
```

### Flux d’une page

1. Route → `SeoPagesController#show`
2. `Registry.find(slug, scope: "local" | "guides")`
3. Chargement produits, pages liées, contexte boutique (si `includes`)
4. Rendu du template `type` : `local_landing`, `style_guide`, `event_guide`, `service_guide`

---

## Fichiers clés

| Fichier | Rôle |
|---------|------|
| `config/seo_pages.yml` | Source de vérité : pages publiées, SEO sitemap, images, modules |
| `config/locales/seo_pages.fr.yml` | Contenu FR + `meta_tags.pages.*` |
| `config/locales/seo_pages.en.yml` | Contenu EN + meta |
| `config/routes.rb` | Routes hub, guides, landings (contrainte slug) |
| `app/services/seo_pages/registry.rb` | Lecture YAML, hub, sitemap, clés i18n |
| `app/helpers/seo_pages_helper.rb` | `seo_page_t`, breadcrumbs, images, hub |
| `app/helpers/meta_tags_helper.rb` | `seo_meta_key` pour titres/descriptions |
| `app/views/public/seo_pages/` | Templates par type + partials `shared/` |

---

## Types de pages

| `type` | Usage | Blocs typiques |
|--------|--------|----------------|
| `local_landing` | SEO géo Cannes | hero, sections, produits, boutique, avis, carte, FAQ, CTA |
| `style_guide` | Conseils mariée / costume | hero, sections (+ image), produits, liens |
| `event_guide` | Occasions (mariage invitée, gala…) | idem |
| `service_guide` | Location, achat vs location | idem + boutique/avis si `includes` |

Le hub `/guides` liste les pages par `hub_group` : `local`, `guides`, `events`, `services`.

---

## Contenu et i18n

- **Clé i18n contenu** : slug avec `-` → `_`  
  Ex. `essayage-robe-de-mariee-cannes` → `public.seo_pages.essayage_robe_de_mariee_cannes.*`
- **Clé meta** : champ `meta_key` dans le YAML (peut différer du slug)  
  Ex. `meta_key: essayage_robe_mariee_cannes` → `meta_tags.pages.essayage_robe_mariee_cannes`
- Helper : `seo_page_t(@page, :header_title)` → traduction automatique selon locale.

⚠️ Le slug YAML et la clé dans `seo_pages.*.yml` doivent correspondre (attention aux `de` dans le slug).

---

## Images

Résolues automatiquement par `SeoPages::CategoryImages` :

- source : produits actifs e-shop des catégories `product_filters.category_names` (+ expansion par slug via `CategoryScope`)
- recherche produit : mot-clé dérivé du slug (`ProductKeywords`, ex. `boheme` → « bohème ») appliqué sur nom, description et catégories — utilisé pour la sélection et le lien « Voir toute la collection »
- sections : un visuel produit différent par section (pas de doublon sur la page) — **vidéo** `Produit#video1` si disponible (Cloudinary), sinon **image** `image1` ; poster = `image1` quand la vidéo en a une
- sélection produits affichée : 6 articles maximum (`SeoPages::ProductScope`)
- liens catégories : boutons vers chaque collection liée à la page (`SeoPages::CategoryScope` étend selon le slug)
- image Open Graph : première image de section disponible

Aucune URL Cloudinary à maintenir dans le YAML.

---

## SEO technique

- **Meta tags** : `@seo_meta_key` → `meta_tags_helper#determine_page_key`
- **Sitemap** : `SeoPages::Registry.sitemap_entries` + `/guides` dans `Sitemap::Builder`
- **JSON-LD** : `WebPage` + `BreadcrumbList` ; `FAQPage` si la page a des entrées `faq` dans les locales (`seo_page_faq_schema`)
- **Hreflang** : layout public (`/fr/…` ↔ `/en/…`, même slug)
- **Produits** : filtre par `product_filters.category_names` (noms exacts en base)

---

## Ajouter une page

1. **Entrée** dans `config/seo_pages.yml` (slug, `scope`, `type`, `meta_key`, `hub_group`, etc.)
2. **Textes** dans `seo_pages.fr.yml` et `seo_pages.en.yml` (même structure de clés)
3. **Meta** dans `meta_tags.pages.<meta_key>` (FR + EN)
4. Redémarrer le serveur en dev si le Registry est mis en cache (`Registry.reload!` en console si besoin)

Les routes guides et locales sont **dynamiques** : pas de modification de `routes.rb` si le slug est déjà couvert par `guides/:slug` ou la contrainte locale.

---

## Tests

- `spec/services/seo_pages/registry_spec.rb`
- `spec/services/seo_pages/category_scope_spec.rb`
- `spec/services/seo_pages/category_images_spec.rb`
- `spec/services/seo_pages/product_keywords_spec.rb`
- `spec/services/seo_pages/product_scope_spec.rb`
- `spec/requests/public/seo_pages_spec.rb`

---

## Évolutions possibles

- Pages dédiées Nice / Monaco / Antibes (landings avec contenu différencié)
- Slugs EN distincts (`slug_en`) pour le SEO anglais
- Liens internes depuis `nos_collections` vers le hub guides
