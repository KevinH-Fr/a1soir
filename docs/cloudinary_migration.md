# Migration Cloudinary — A1soir

Bascule vers un **nouveau cloud** en conservant les mêmes `public_id` (= `active_storage_blobs.key`). **Pas de changement en base.**

Script : `lib/tasks/cloudinary_copy.rake`.

| | Compte |
|---|---|
| Source (`CLOUDINARY_*`) | ancien — prod actuelle |
| Dest (`CLOUDINARY_DEST_*`) | nouveau — tests puis future prod |

`CLOUDINARY_USE=source|dest` : interrupteur **local** (ce que Rails affiche). Le rake **ignore** ça : il lit toujours source, écrit toujours dest.

**Ne pas** mettre `CLOUDINARY_DEST_*` ni `CLOUDINARY_USE` sur Heroku prod.

---

## Étapes de bascule

### 0. Prérequis (local)

- **Passer le nouveau compte en plan payant avant la copie complète.** Le Free refuse les fichiers **> 10 Mo** (`File size too large. Maximum is 10485760`) et le quota **25 crédits** ne tiendra pas ~6 000 médias + transformations. Déjà bloqué en static : `equipe1_qgcprn`, `equipe2_aubkac` (~15 Mo). Alternative ponctuelle : recompresser ces 2 images sous 10 Mo — insuffisant pour la prod (vidéos, uploads admin).
- Nouveau compte : delivery **authenticated**, CORS prod + `localhost:3000`.
- `.env` : `CLOUDINARY_*` = ancien, `CLOUDINARY_DEST_*` = nouveau, `CLOUDINARY_DEST_FOLDER=A1soir`.
- Smoke test : `bin/rails cloudinary:copy_assets ONLY=faq1_fp6utw` puis `CLOUDINARY_USE=dest`.
- Pages publiques statiques seulement (sans les blobs Active Storage) :

```bash
bin/rails cloudinary:list_assets INCLUDE=static
bin/rails cloudinary:copy_assets INCLUDE=static
```

Puis `CLOUDINARY_USE=dest` + restart Rails pour les voir en local.

### 1. Catalogue = DB **prod** (pas le sqlite local)

```bash
heroku run rake cloudinary:list_assets -a a1soir-2
```

Coller / récupérer la liste → `tmp/cloudinary_allowlist.txt` (gitignoré).

`list_assets` local = blobs de **ta** DB + IDs du code. Utile pour tester, pas pour coller à la prod.

### 2. Copier **depuis le laptop** (prod reste sur l’ancien)

```bash
bin/rails cloudinary:copy_assets ALLOWLIST=tmp/cloudinary_allowlist.txt
```

Relancer = skip si déjà présent (`OVERWRITE=1` pour forcer).

### 3. Valider en local (`CLOUDINARY_USE=dest`)

- [ ] Produit existant (image + vidéo)
- [ ] Pages marketing
- [ ] PDF, feed Google Merchant
- [ ] Upload admin (nouveau fichier arrive bien sur dest)

Si l’admin a uploadé pendant la copie : re-`list_assets` Heroku + relancer la copie.

### 4. Gel court + rattrapage

Limiter les uploads prod, re-lister, re-copier.

### 5. Cutover Heroku

Déployer le code qui construit les URLs via `CLOUDINARY_CLOUD_NAME` (helpers, pas d’URLs en dur).

Puis **remplacer** les 3 vars classiques (pas un « mode dest ») :

```bash
heroku config:set \
  CLOUDINARY_CLOUD_NAME=a1soir-1 \
  CLOUDINARY_KEY=… \
  CLOUDINARY_SECRET=… \
  -a a1soir-2
heroku restart -a a1soir-2
```

Vérifier site + upload admin.

**Rollback** : remettre les anciennes 3 vars + restart. Garder l’ancien compte **quelques semaines**.

### 6. Après validation (pas le jour J)

- Local : `CLOUDINARY_*` = **autre** cloud que la prod (l’ancien compte convient comme bac à sable).
- Supprimer `DEST_*` et `CLOUDINARY_USE`.
- Garder le rake tant qu’il reste des oublis / `missing_source`, puis le retirer.

---

## Dossier `A1soir` et liens

| | Effet sur les URLs |
|---|---|
| `asset_folder: A1soir` (script actuel) | Rangement Media Library. **URL inchangée.** |
| `folder: "A1soir"` (fixed folders) | ID = `A1soir/xxx` → **liens cassés.** Ne pas faire. |

L’app sert `https://res.cloudinary.com/{cloud_name}/image/upload/…/{public_id}` **sans** préfixe dossier.

Les liens **ne sont pas forcément cassés** après bascule : même ID + nouveau `cloud_name` = OK.

Ça casse si : fichier non copié, ID préfixé, ou URL encore en dur vers `dukne3lhz`.

---

## Dev vs prod (pas des dossiers)

Aujourd’hui local et prod partagent **les mêmes clés** → un upload local peut écraser un média prod.

Un dossier Cloudinary `dev/` vs `prod/` **n’isole pas** : même quota, mêmes `public_id`. Isolation = **deux clouds**.

Après bascule :

| | Cloud |
|---|---|
| Prod Heroku | nouveau (`a1soir-1`) |
| Dev local | ancien compte (ou un 3ᵉ produit plus tard) |

Jamais les clés prod dans le `.env` local une fois la prod basculée.

---

## Commandes utiles

```bash
bin/rails cloudinary:which
bin/rails cloudinary:list_assets INCLUDE=static
bin/rails cloudinary:copy_assets INCLUDE=static
bin/rails cloudinary:copy_assets DRY_RUN=1
bin/rails cloudinary:copy_assets ONLY=faq1_fp6utw
bin/rails cloudinary:copy_assets LIMIT=50
bin/rails cloudinary:copy_assets ALLOWLIST=tmp/cloudinary_allowlist.txt
```
