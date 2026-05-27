### Plan complet — Option B (titres SEO par famille)

#### Principe de nommage (Option B)

- **`new_nom`** : titre SEO **identique pour toutes les variantes d'une même famille** (même `handle` actuel).
- **Ne pas inclure** couleur ni taille dans `new_nom` — elles restent dans `couleur_id` / `taille_id` (affichées sur la fiche).
- **`handle`** : recalculé au `save` via `generate_handle` (`nom.parameterize`). Ce n’est **pas** l’ancien handle qui est conservé (ex. `melyna` → `robe-soiree-melyna`), mais le **même nouveau handle entre toutes les variantes** d’une famille.
- **Slug URL** : `handle` + `-` + `id` (pas de colonne slug en DB). Après import, `handle` et `nom.parameterize` sont alignés ; utiliser **`handle`** comme référence canonique (301, liens, sitemap).

**Exemple famille « Melyna »** (3 variantes taille/couleur) :

| id   | old_nom | new_nom (partagé)   | handle après import | URL exemple                           |
|------|---------|---------------------|---------------------|---------------------------------------|
| 2827 | Melyna  | Robe soirée Melyna  | robe-soiree-melyna  | `/fr/produit/robe-soiree-melyna-2827` |
| 2828 | Melyna  | Robe soirée Melyna  | robe-soiree-melyna  | `/fr/produit/robe-soiree-melyna-2828` |
| 2829 | Melyna  | Robe soirée Melyna  | robe-soiree-melyna  | `/fr/produit/robe-soiree-melyna-2829` |

Couleur et taille : affichées sur la fiche via les champs existants, pas dans le titre SEO.

**Pourquoi Option B** : le `handle` regroupe les variantes (autres tailles/couleurs, déduplication grille, `item_group_id` Google Merchant). Un `new_nom` distinct par variante fragmenterait ces regroupements.

#### Décisions techniques validées

1. **Slug canonique = `handle`** (pas `nom.parameterize` directement) — avec fallback si `handle` vide : `handle.presence || nom.parameterize`.
2. **301 sans `back_url`** — URL canonique pure (évite des variantes indexables avec query string). La navigation `back_url` reste gérée en session une fois sur l’URL canonique.
3. **Wording handle** — on préserve la **cohérence entre variantes**, pas la valeur historique du handle.
4. **Stripe** — nom identique entre variantes : non bloquant ; en import bulk, préférer `Stripe::Product.update(..., { name: })` seul (voir étape 10). `StripeProductService` ne recrée un `Price` que si `prixvente` a changé sur le même `save`.
5. **Merchant `g:item_group_id`** — vaut `produit.handle` dans le flux ([`FeedBuilder`](app/services/google_merchant/feed_builder.rb)). Après import, la valeur **change** (ex. `melyna` → `robe-soiree-melyna`) : ce n’est pas grave. Ce qui compte : **identique entre variantes d’une même famille**, pas identique à l’ancien handle.

**Flux validé** :

```text
Option B par famille
→ new_nom identique par ancien handle
→ update!(nom: new_nom)
→ handle recalculé automatiquement (identique entre variantes)
→ 301 via id vers handle actuel (sans query)
→ sitemap dynamique à jour
→ sitemap resoumis GSC
→ Merchant vérifié (nouveau item_group_id cohérent par famille)
→ Stripe : nom produit synchronisé (sans toucher aux Price)
```

**Contrôle pré-migration (console)** — détecter handle / nom désynchronisés :

```ruby
Produit.where(handle: [nil, ""]).count
# Comparer handle vs nom.parameterize sur un échantillon avant bascule globale vers slug = handle
```

---

## Outils et exécution (local d'abord, puis prod)

### Stack / outils

| Besoin | Outil | Notes |
|--------|--------|--------|
| App locale | `bin/rails server` (WSL) | `http://localhost:3000` — voir [`Procfile.dev`](Procfile.dev) |
| Console Rails | `bin/rails console` | export, dry-run import, vérifs `handle` |
| Tests auto | `bundle exec rspec` | ex. `spec/requests/public/pages_slug_redirect_spec.rb` pour la 301 |
| Export / import CSV | `rails runner` ou tâche rake | pas encore de rake dédiée — voir snippets ci-dessous |
| Édition / validation CSV | LibreOffice Calc, Excel ou Google Sheets | filtres par `handle`, colonne `approved` |
| Génération titres IA | ChatGPT / Claude / script maison | **hors app** ; une ligne `new_nom` par `handle` |
| Contrôle cohérence CSV | Ruby (script ou runner) | vérifier `new_nom` identique par `handle` avant import |
| Redirections / sitemap / flux | `curl` | headers HTTP, grep dans XML gzip |
| Stripe (local) | Dashboard **mode test** + `StripeProductService` | clés `STRIPE_*` en `.env` / `config/credentials` |
| Stripe (prod) | Dashboard live + `heroku run rails console` | ne pas recréer Product/Price |
| Backup prod | Heroku Postgres backups | `heroku pg:backups:capture -a a1soir-2` |
| Données prod en local (optionnel) | `heroku pg:backups:download` ou `DATABASE_URL` | pour tester l'import sur copie réelle — **one-shot**, ne pas laisser `DATABASE_URL` exporté |
| Déploiement code | Git + Heroku | branche d'intégration → `main` → deploy (voir [`docs/maj git.md`](maj%20git.md)) |
| SEO post-migration | Google Search Console | resoumission `https://a1soir.com/sitemap.xml.gz` |
| Shopping | Google Merchant Center | flux `https://a1soir.com/google_merchant_feed.xml` ([`docs/google_merchant_feeds.md`](google_merchant_feeds.md)) |

App Heroku documentée : **`a1soir-2`** (domaine public : `https://a1soir.com`).

### Ordre recommandé

```text
LOCAL — code
  → implémenter 301 + spec
  → bundle exec rspec
  → tester à la main sur localhost

LOCAL — données (copie ou échantillon)
  → export CSV
  → IA + validation CSV (approved)
  → dry-run import (aucune écriture)
  → import sur 5–10 produits test
  → curl 301 + fiches + variantes

PROD — si local OK
  → backup Heroku
  → deploy 301 (seul changement code si import pas encore fait)
  → export CSV prod
  → IA + validation
  → import prod (fenêtre courte)
  → vérifs curl + Stripe + GSC / Merchant
```

---

### Phase locale — commandes utiles

**Démarrer l'app**

```bash
cd ~/ror/a1soir
bin/rails server
# ou : foreman start -f Procfile.dev
```

**Tests (301 et régressions)**

```bash
bundle exec rspec spec/requests/public/pages_slug_redirect_spec.rb
bundle exec rspec spec/requests/public/
```

**Tester une 301 à la main**

```bash
# slug correct → 200
curl -sI "http://localhost:3000/fr/produit/robe-melyna-123" | head -5

# slug obsolète → 301 (remplacer id par un produit réel)
curl -sI "http://localhost:3000/fr/produit/melyna-123" | grep -E 'HTTP|Location'
```

**Exporter les produits (console ou runner)**

```bash
bin/rails runner "
  require 'csv'
  path = Rails.root.join('tmp/produits_export.csv')
  CSV.open(path, 'w', write_headers: true, headers: %w[id handle old_nom couleur taille description stripe_product_id]) do |csv|
    Produit.includes(:couleur, :taille).find_each do |p|
      csv << [p.id, p.handle, p.nom, p.couleur&.nom, p.taille&.nom, p.description, p.stripe_product_id]
    end
  end
  puts \"Écrit : #{path}\"
"
```

**Valider le CSV avant import (cohérence Option B)**

```bash
bin/rails runner "
  require 'csv'
  path = 'tmp/produits_import.csv' # id,handle,old_nom,new_nom,approved,notes
  rows = CSV.read(path, headers: true)
  approved = rows.select { |r| r['approved'].to_s =~ /^(1|true|oui|yes)$/i }
  by_handle = approved.group_by { |r| r['handle'] }
  errors = by_handle.filter_map do |handle, group|
    names = group.map { |r| r['new_nom'].to_s.strip }.uniq
    \"handle=#{handle} : #{names.size} new_nom distincts → #{names.inspect}\" if names.size > 1
  end
  abort(errors.join(\"\\n\")) if errors.any?
  puts \"OK : #{approved.size} lignes, #{by_handle.size} familles\"
"
```

**Dry-run import (aucune écriture)**

```bash
bin/rails runner "
  require 'csv'
  rows = CSV.read('tmp/produits_import.csv', headers: true)
  rows.select { |r| r['approved'].to_s =~ /^(1|true|oui|yes)$/i }.each do |r|
    p = Produit.find_by(id: r['id'])
    next puts \"SKIP id=#{r['id']} introuvable\" unless p
    puts \"[dry-run] ##{p.id} : #{p.nom.inspect} → #{r['new_nom'].inspect} (handle #{p.handle} → #{r['new_nom'].parameterize})\"
  end
"
```

**Import réel (échantillon ou lot complet)**

```bash
# Préférer update + callbacks (handle + Stripe si vente en ligne)
bin/rails runner "
  require 'csv'
  rows = CSV.read('tmp/produits_import.csv', headers: true)
  rows.select { |r| r['approved'].to_s =~ /^(1|true|oui|yes)$/i }.each do |r|
    p = Produit.find(r['id'])
    p.update!(nom: r['new_nom'].strip)
    if p.stripe_product_id.present? && OnlineSales.available?
      Stripe::Product.update(p.stripe_product_id, { name: p.nom })
    end
    puts \"OK ##{p.id} → #{p.nom} (handle=#{p.handle})\"
  rescue => e
    puts \"ERREUR ##{r['id']}: #{e.message}\"
  end
"
```

> **Ne pas utiliser** `update_column(:nom, ...)` : ça bypass `generate_handle` et la sync Stripe.

**Sitemap / Merchant en local**

```bash
curl -sI http://localhost:3000/sitemap.xml.gz | head -5
curl -sL http://localhost:3000/sitemap.xml.gz | gunzip | grep 'fr/produit/' | head -3
curl -sL http://localhost:3000/google_merchant_feed.xml | head -40
```

Réf. sitemap : [`docs/SITEMAP_PROD.md`](SITEMAP_PROD.md).

---

### Phase prod — commandes utiles

**1. Backup (avant toute modification de données)**

```bash
heroku pg:backups:capture -a a1soir-2
heroku pg:backups -a a1soir-2   # vérifier que le backup est récent
```

**2. Déployer le code (301 seule, possible avant renommage)**

```bash
git checkout -b feature/produit-slug-301
# commit + push → merge main selon docs/maj git.md
git push heroku main   # ou la remote/branche utilisée pour a1soir-2
```

**3. Vérifier la 301 en prod (sans avoir encore renommé → surtout 200)**

```bash
curl -sI "https://a1soir.com/fr/produit/<slug-actuel>-<id>" | head -5
```

**4. Export CSV depuis prod**

```bash
heroku run 'rails runner "
  require \"csv\"
  path = \"/tmp/produits_export.csv\"
  CSV.open(path, \"w\", write_headers: true, headers: %w[id handle old_nom couleur taille description stripe_product_id]) do |csv|
    Produit.includes(:couleur, :taille).find_each { |p| csv << [p.id, p.handle, p.nom, p.couleur&.nom, p.taille&.nom, p.description, p.stripe_product_id] }
  end
  puts File.read(path)
"' -a a1soir-2 > produits_export_prod.csv
```

(Alternative : copier le fichier via `heroku run bash` + `cat`, ou exporter en local avec `DATABASE_URL` prod **temporairement** — voir [`docs/SITEMAP_PROD.md`](SITEMAP_PROD.md).)

**5. Import prod (fenêtre maintenance courte)**

```bash
# Copier le CSV validé sur le dyno ou coller le runner avec chemin adapté
heroku run rails console -a a1soir-2
# puis coller la boucle update! + StripeProductService (même logique que local)
```

**6. Contrôles post-import**

```bash
curl -sI "https://a1soir.com/fr/produit/<ancien-slug>-<id>" | grep -E 'HTTP|Location'
curl -sL https://a1soir.com/sitemap.xml.gz | gunzip | grep 'robe-soiree-melyna' | head -3
curl -sL https://a1soir.com/google_merchant_feed.xml | grep -A2 'item_group_id' | head -20
heroku logs --tail -a a1soir-2   # surveiller 404 / erreurs
```

**7. Search Console / Merchant**

- GSC → Indexation → Sitemaps → `https://a1soir.com/sitemap.xml.gz` (resoumettre)
- Merchant Center → flux produits → vérifier récupération et erreurs URL / `item_group_id`

---

1. **Backup prod**

   * backup DB Heroku ;
   * export CSV produits avant modification.

2. **Ajouter la 301 automatique**

   * dans `Public::PagesController#produit` (juste après `Produit.find`) :

   ```ruby
   @produit = Produit.find(params[:id])
   expected_slug = @produit.handle.presence || @produit.nom.parameterize

   if params[:slug] != expected_slug
     return redirect_to(
       produit_path(slug: expected_slug, id: @produit.id),
       status: :moved_permanently
     )
   end
   ```

   * **ne pas** inclure `back_url` (ni autre query) dans la 301 — URL canonique SEO pure ;
   * déployer **avant** l'import des `new_nom`.

   **Sans impact tant que les noms n'ont pas changé** : la 301 ne s'active que si `params[:slug] != handle` (ou `nom.parameterize` si handle vide). Tant que le slug de l’URL correspond au handle actuel, la fiche répond en **200** comme aujourd'hui. Après renommage CSV, les anciennes URLs déclencheront la 301 vers le nouveau handle.

3. **Vérifier les liens internes**

   * cible recommandée — utiliser `handle` comme slug :

   ```ruby
   produit_path(slug: produit.handle, id: produit.id)
   ```

   * le code actuel utilise souvent `produit.nom.parameterize` : équivalent **tant que** `handle == nom.parameterize` après chaque save. Migrer vers `handle` progressivement ou en une passe pour une seule source de vérité (aligné avec sitemap, Merchant, chatbot).

4. **Vérifier la canonical produit**

   * chaque fiche doit avoir une canonical vers l'URL actuelle (layout `public.html.erb` via `url_for`) ;
   * la 301 garantit que seule l'URL canonique (nouveau slug) est servie en 200.

5. **Exporter les produits**

   ```csv
   id,handle,old_nom,couleur,taille,description,stripe_product_id
   ```

   * **`handle`** : clé de regroupement famille — indispensable pour Option B ;
   * exporter `couleur` et `taille` (libellés) pour aider l'IA à rédiger sans les mettre dans `new_nom`.

6. **Génération IA hors app (par famille, pas par SKU)**

   * grouper les lignes CSV par `handle` ;
   * générer **un seul `new_nom` par `handle`** (titre SEO famille) ;
   * ne pas inclure couleur ni taille dans le titre proposé ;
   * pas de slug en DB ; slug URL = `handle` recalculé après import (`generate_handle`).

   **Prompt IA — contraintes** :

   * produire un titre descriptif SEO (type de produit + modèle/marque si pertinent) ;
   * **exclure** couleur, taille, pointure ;
   * **même `new_nom` pour toutes les lignes d'un même `handle`**.

7. **Valider le CSV**

   ```csv
   id,handle,old_nom,new_nom,approved,notes
   ```

   **Contrôles de validation obligatoires** :

   * pour un même `handle`, tous les `new_nom` approuvés doivent être **strictement identiques** ;
   * rejeter toute ligne où `new_nom` contient une couleur ou taille déjà présente dans les champs dédiés ;
   * vérifier manuellement un échantillon de familles multi-variantes.

8. **Importer les nouveaux noms**

   * remplacer `nom` par `new_nom` validé (même valeur pour toutes les variantes d'une famille) ;
   * laisser `before_validation :generate_handle` recalculer `handle` → **même nouveau handle entre variantes** (pas l’ancien handle conservé) ;
   * préférer un script rake avec dry-run plutôt que des `update_column` (callbacks Stripe + handle).

9. **Tester les redirections et les variantes**

   * ancienne URL :

   ```text
   /fr/produit/melyna-2827
   ```

   * doit renvoyer `301` vers :

   ```text
   /fr/produit/robe-soiree-melyna-2827
   ```

   * **pas** vers une URL incluant la couleur (Option B) ;
   * vérifier que les blocs « autres tailles » / « autres couleurs » fonctionnent encore (même `handle`) ;
   * vérifier la déduplication en grille (`FiltersProduitsService`).

10. **Sync Stripe**

    **Import bulk (recommandé — nom seul)** :

    ```ruby
    Stripe::Product.update(produit.stripe_product_id, { name: produit.nom })
    ```

    * ne touche pas aux `Price` ;
    * ne modifie pas images / description.

    **`StripeProductService#update_product_and_price`** (admin, hors migration bulk) :

    * appelle `Stripe::Product.update` (name, description, images) ;
    * ne recrée un `Price` **que si** `saved_change_to_prixvente?` sur le produit ([`apply_stripe_updates`](app/services/stripe_product_service.rb)) — OK après `update!(nom:)` seul ;
    * attention : peut envoyer `images: []` et effacer les images Stripe si pas d’`image1` — éviter en import massif, préférer l’appel `name` seul ci-dessus.

    * le **nom affiché** Stripe sera le titre famille (identique entre variantes) : **non bloquant** pour le checkout ;
    * chaque variante reste identifiable par **`stripe_product_id`**, **`stripe_price_id`**, metadata `produit_id` ;
    * ne pas recréer les produits Stripe ;
    * spot-check Dashboard sur 2–3 familles multi-variantes après import prod.

11. **Sitemap**

    * sitemap dynamique (`Sitemap::Builder`) — nouvelles URLs automatiques après import ;
    * vérifier un échantillon : `curl -sL https://a1soir.com/sitemap.xml.gz | gunzip | grep 'robe-soiree-melyna'`.

12. **Ressoumettre le sitemap**

    * Google Search Console ;
    * Bing Webmaster Tools si utilisé.

13. **Merchant Center**

    * vérifier que les URLs produits du flux sont à jour (`g:link` recalculé depuis le nouveau slug) ;
    * `g:item_group_id` = `produit.handle` : **change** après import (ex. `melyna` → `robe-soiree-melyna`) — normal, pas bloquant ;
    * vérifier qu’il reste **identique entre variantes d'une même famille** (regroupement Shopping conservé) ;
    * ne pas confondre avec « conserver l’ancien handle » ;
    * relancer / attendre la récupération du flux ;
    * contrôler les erreurs produits dans Merchant Center (24–48 h).

14. **Contrôles post-migration**

    * vérifier plusieurs fiches produit (dont familles multi-variantes) ;
    * vérifier affichage couleur/taille sur fiche malgré titre partagé ;
    * vérifier checkout Stripe ;
    * vérifier canonical ;
    * vérifier sitemap ;
    * tester anciennes URLs ;
    * surveiller logs 404.

15. **Suivi SEO**

    * Search Console :

      * pages indexées ;
      * redirections ;
      * erreurs 404 ;
      * couverture sitemap ;
      * performances produits.
    * surveiller pendant 2 à 4 semaines.

**Conclusion** : Option B par famille → `new_nom` identique par ancien handle → `update!(nom:)` → **même nouveau handle entre variantes** → URL canonique `handle-id` → 301 depuis ancien slug → sitemap à jour → resoumission GSC → Merchant vérifié (nouveau `item_group_id` cohérent par famille) → Stripe : `Product.update` nom seul. Suffisant et propre pour Google.




## Migration SEO noms produits / handles — étapes production

### Objectif

Renommer les produits pour obtenir :
- un `nom` SEO plus descriptif ;
- un `handle` recalculé automatiquement via `generate_handle`;
- une URL canonique `/fr/produit/<handle>-<id>`;
- une redirection 301 depuis les anciennes URLs;
- un sitemap et un flux Merchant à jour automatiquement.

---

### 1. Déployer la redirection 301 avant l’import

Vérifier que `Public::PagesController#produit` contient :

```ruby
@produit = Produit.find(params[:id])
expected_slug = @produit.handle.presence || @produit.nom.parameterize

if params[:slug] != expected_slug
  return redirect_to(
    produit_path(slug: expected_slug, id: @produit.id),
    status: :moved_permanently
  )
end