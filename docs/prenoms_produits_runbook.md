# Prénoms produits — runbook

Comparer `tmp/prenoms_femmes_france.csv` aux `Produit.nom` et produire **deux fichiers de résultat** (dev et prod), sans modifier la liste source.

**Tâche** : `bin/rails products:prenoms_utilises` — [`lib/tasks/products_prenoms.rake`](../lib/tasks/products_prenoms.rake)

---

## Fichiers (`tmp/`, gitignore)

| Fichier | Rôle |
|---------|------|
| `prenoms_femmes_france.csv` | **Entrée** — colonne `prenom` uniquement (jamais écrasé par défaut) |
| `prenoms_femmes_france_dev.csv` | **Sortie** — test base locale |
| `prenoms_femmes_france_prod.csv` | **Sortie** — test base prod (`DATABASE_URL`) |

Colonnes de sortie : `prenom`, `utilise` (`oui` / `non`), `produits_trouves`.

Prénoms libres : filtrer `utilise` = `non` dans le fichier voulu.

---

## Impact

| | |
|-|-|
| Lit la base connectée | Oui |
| Crée / met à jour les CSV `_dev` / `_prod` | Oui |
| Modifie `prenoms_femmes_france.csv` (source) | **Non** (sauf `IN_PLACE=true`) |
| Écrit en base | **Non** |

---

## Commandes

```bash
cd ~/ror/a1soir

# 1) Base locale → tmp/prenoms_femmes_france_dev.csv
SOURCE=dev bin/rails products:prenoms_utilises

# 2) Base prod → tmp/prenoms_femmes_france_prod.csv
export DATABASE_URL="$(heroku config:get DATABASE_URL -a a1soir-2)"
SOURCE=prod bin/rails products:prenoms_utilises
unset DATABASE_URL
```

Test rapide (500 lignes) :

```bash
LIMIT=500 SOURCE=dev OUTPUT=tmp/prenoms_sample_dev.csv bin/rails products:prenoms_utilises
```

Vérif :

```bash
head -3 tmp/prenoms_femmes_france_dev.csv
head -3 tmp/prenoms_femmes_france_prod.csv
```

La fin de tâche affiche le **fichier écrit** et le nom de la **base** utilisée.

---

## Variables

| Variable | Défaut | Exemple |
|----------|--------|---------|
| `INPUT` | `tmp/prenoms_femmes_france.csv` | liste source |
| `SOURCE` | `dev` | `prod` → sortie `tmp/prenoms_femmes_france_prod.csv` |
| `OUTPUT` | selon `SOURCE` | chemin custom |
| `IN_PLACE` | `false` | `true` pour écraser `INPUT` (déconseillé) |
| `LIMIT` | tout | `500` |

---

## Notes

- Lancer **dev** puis **prod** : tu gardes les deux comparatifs côte à côte.
- Rake + CSV en gitignore : outil local, pas sur Heroku.
