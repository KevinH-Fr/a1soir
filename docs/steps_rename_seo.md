Oui, il faut surtout adapter la partie **prod** pour utiliser `STDIN`.

## Dev

1. **Tester la redirection**

   * ancienne URL → `301`
   * nouvelle URL → `200`

2. **Exporter CSV dev**

   ```bash
   bin/rails products:seo_export
   ```

3. **Récupérer le fichier**

   ```text
   tmp/produits_seo_export.csv
   ```

4. **Générer les noms SEO hors app**

    À partir de ce CSV produits, génère un nouveau CSV avec les colonnes :
    id,handle,old_nom,new_nom,approved,notes

    Règles :
    - regrouper par handle ;
    - générer un seul new_nom identique pour toutes les lignes d’un même handle ;
    - construire new_nom à partir de la description produit ;
    - utiliser un format court et naturel de type :
    [type de produit] + [élément distinctif principal] + [nom modèle]
    - utiliser le prénom/modèle à la fin pour différencier les produits ;
    - éviter les titres trop génériques ;
    - ne pas inclure couleur, taille, pointure ou référence technique ;
    - ne pas inventer d’informations absentes de la description ;
    - éviter le bourrage SEO ;
    - approved=yes uniquement si le produit semble réel et exploitable ;
    - laisser approved vide pour les produits tests, brouillons ou incohérents ;
    - répondre uniquement avec le CSV final.

   * sortie :

   ```csv
   id,handle,old_nom,new_nom,approved,notes
   ```

5. **Placer le CSV d’import**

   ```bash
   cp produits_seo_import.csv tmp/
   ```

6. **Dry-run dev**

   ```bash
   bin/rails products:seo_import[tmp/produits_seo_import.csv]
   ```

7. **Import réel dev**

   ```bash
   DRY_RUN=false bin/rails products:seo_import[tmp/produits_seo_import.csv]
   ```

8. **Vérifs dev**

   * ancienne URL → `301`
   * nouvelle URL → `200`
   * sitemap contient nouveau handle
   * Merchant contient nouveau `g:title`, `g:link`, `g:item_group_id`

---

## Prod

1. **Déployer la redirection 301 + tâches rake**

2. **Backup prod**

   ```bash
   heroku pg:backups:capture -a a1soir-2
   ```

3. **Exporter CSV prod**

   ```bash
   heroku run 'bin/rails products:seo_export' -a a1soir-2 > produits_seo_export_prod.csv
   ```

4. **Générer les noms SEO hors app**

   * donner `produits_seo_export_prod.csv` à l’IA
   * récupérer :

   ```text
   produits_seo_import_prod.csv
   ```

5. **Dry-run prod via STDIN**

   ```bash
   cat produits_seo_import_prod.csv | heroku run 'bin/rails products:seo_import' -a a1soir-2
   ```

6. **Import réel prod via STDIN**

   ```bash
   cat produits_seo_import_prod.csv | heroku run 'DRY_RUN=false bin/rails products:seo_import' -a a1soir-2
   ```

7. **Vérifs prod**

   ```bash
   curl -sI "https://a1soir.com/fr/produit/<ancien-handle>-<id>"
   curl -sI "https://a1soir.com/fr/produit/<nouveau-handle>-<id>"
   curl -sL https://a1soir.com/sitemap.xml.gz | gunzip | grep '<nouveau-handle>'
   curl -sL https://a1soir.com/google_merchant_feed.xml | grep -A20 '<nouveau-handle>'
   ```

8. **Google**

   * resoumettre :

   ```text
   https://a1soir.com/sitemap.xml.gz
   ```

   * vérifier Merchant Center
   * surveiller 404 / indexation / checkout Stripe.
