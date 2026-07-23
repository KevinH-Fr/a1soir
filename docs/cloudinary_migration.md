# Migration Cloudinary — A1soir

Guide synthétique pour basculer vers un nouveau compte Cloudinary sans casser l'app.

## Architecture actuelle

| Couche | Fichiers clés | Rôle |
|--------|---------------|------|
| Config | `config/initializers/cloudinary.rb` | `cloud_name` hardcodé (`dukne3lhz`), clés via `CLOUDINARY_KEY` / `CLOUDINARY_SECRET` |
| Uploads | `config/storage.yml`, `development.rb`, `production.rb` | ActiveStorage → Cloudinary (`type: authenticated`) |
| URLs dynamiques | `app/helpers/application_helper.rb` | `cloudinary_attachment_url(blob.key)` — produits, catégories, PDF, feed Google |
| URLs statiques | `app/views/public/pages/*`, `pages_controller.rb` | ~50 URLs hardcodées (FAQ, contact, landing Festival…) |

**Règle importante** : les URLs produits sont reconstruites depuis `active_storage_blobs.key` (= `public_id` Cloudinary). Si on copie les fichiers avec le **même public_id**, pas de changement en base.

---

## Filtrer uniquement les médias A1soir

Le compte Cloudinary peut contenir d'autres médias (autres projets, tests, uploads manuels). **Ne pas migrer tout le compte** — construire une liste blanche (allowlist).

### Source 1 — ActiveStorage (catalogue, admin)

Liste de référence depuis la base prod :

```bash
heroku run rails runner "puts ActiveStorage::Blob.distinct.pluck(:key).sort" -a a1soir-2 > cloudinary_blobs_a1soir.txt
```

Modèles concernés : `Produit` (image1, video1, images), `CategorieProduit`, `Texte`, `Profile`, `Commande`.

### Source 2 — Médias statiques (pages marketing)

Extraire les `public_id` hardcodés dans le code :

```bash
rg -o 'res\.cloudinary\.com/dukne3lhz/(?:image|video)/upload/[^/]+/([^"'\''\s\)]+)' app/ \
  | sed 's/.*\///' \
  | sed 's/\.mp4$//' \
  | sort -u > cloudinary_static_a1soir.txt
```

Fichiers principaux : `app/views/public/pages/`, `app/controllers/public/pages_controller.rb`, `application_helper.rb` (`no_photo_url`).

### Liste finale

```bash
cat cloudinary_blobs_a1soir.txt cloudinary_static_a1soir.txt | sort -u > cloudinary_allowlist_a1soir.txt
wc -l cloudinary_allowlist_a1soir.txt   # nombre de médias à migrer
```

### Vérifier côté Cloudinary (optionnel)

Lister les ressources du compte et ne garder que celles de l'allowlist :

```ruby
# rails runner (avec clés de l'ANCIEN compte)
allowlist = File.readlines("cloudinary_allowlist_a1soir.txt", chomp: true).to_set

Cloudinary::Api.resources(type: "authenticated", max_results: 500).each do |batch|
  batch["resources"].each do |r|
    id = r["public_id"]
    puts id if allowlist.include?(id)
  end
end
```

**Ne migrer que les public_id présents dans `cloudinary_allowlist_a1soir.txt`.**

---

## Phases de migration

### 0. Nouveau compte Cloudinary

Reproduire les réglages de l'ancien :

- Delivery type : **authenticated**
- CORS : domaines prod + `localhost:3000`
- Noter : cloud name, API key, API secret

### 1. Centraliser la config (code)

Remplacer `dukne3lhz` en dur par `ENV['CLOUDINARY_CLOUD_NAME']` dans :

- `config/initializers/cloudinary.rb`
- `app/helpers/application_helper.rb` (constantes `CLOUDINARY_BASE_*`)
- specs associées

Variables à gérer partout :

```bash
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_KEY=...
CLOUDINARY_SECRET=...
```

### 2. Copier les médias

Pour chaque `public_id` de l'allowlist, copier vers le nouveau compte **en conservant le même public_id** :

```ruby
Cloudinary::Uploader.upload(
  "https://res.cloudinary.com/ANCIEN_CLOUD/image/authenticated/s--TOKEN--/PUBLIC_ID",
  public_id: "PUBLIC_ID",
  type: "authenticated",
  resource_type: "auto"   # image ou video
)
```

Alternative : script rake qui boucle sur l'allowlist + API Admin Cloudinary.

Pages statiques : même principe, puis remplacer `dukne3lhz` par le nouveau cloud name dans les vues (ou migrer vers les helpers `cloudinary_image`).

### 3. Tester en local

Créer un `.env` avec les **nouvelles** clés (dotenv déjà installé).

Checklist :

- [ ] Upload d'une image test en admin
- [ ] Affichage d'un produit existant (blob migré)
- [ ] Vidéo produit (`_carousel.html.erb`)
- [ ] Feed Google Merchant
- [ ] PDF (vignettes produit)

Test minimal sans migration complète : uploader 1 produit test → valide le branchement. Les anciens produits resteront cassés tant qu'ils ne sont pas migrés.

### 4. Basculer la prod

Ordre impératif :

1. Migrer tous les médias de l'allowlist
2. Déployer le code (cloud_name en ENV)
3. Changer les variables Heroku :

```bash
heroku config:set CLOUDINARY_CLOUD_NAME=... CLOUDINARY_KEY=... CLOUDINARY_SECRET=... -a a1soir-2
heroku restart -a a1soir-2
```

4. Vérifier pages + upload admin

**Rollback** : remettre les anciennes variables Heroku + restart. Garder l'ancien compte en backup plusieurs semaines.

---

## Ce qui casse / ne casse pas

| Élément | Casse sans migration ? |
|---------|------------------------|
| Images / vidéos produits | Oui |
| Feed Google Merchant, PDF | Oui |
| Pages marketing (URLs encore sur ancien compte) | Non |
| Nouveaux uploads admin | Non (si clés OK) |

---

## Résumé

```
Allowlist (DB + code) → Copier avec même public_id → Centraliser ENV → Test local → Switch Heroku
```

Pas de migration de schéma DB si les public_id sont conservés.
