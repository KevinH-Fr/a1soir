Oui, il faut surtout adapter la partie **prod** pour utiliser `STDIN`.

manual backup heroku avant push prod des rakes et modifs de code pas de db le 27052026 (b375)
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

4. **Générer les noms SEO (IA locale par batch)**

   **Test rapide (5 familles, ~1 appel API)** :

   ```bash
   # OPENAI_API_KEY dans .env
   bin/rails products:seo_ai_dev_sample
   # ou : LIMIT=10 bin/rails products:seo_ai_dev_sample
   ```

   **Catalogue dev complet** :

   ```bash
   bin/rails products:seo_export
   bin/rails products:seo_ai_prepare
   bin/rails products:seo_ai_generate
   bin/rails products:seo_ai_build_import
   bin/rails products:seo_ai_validate
   ```

   Fichiers dev par défaut :
   - export : `tmp/produits_seo_export.csv`
   - import  : `tmp/produits_seo_import.csv`
   - batches : `tmp/seo_ai/batches/`

   Reprise : `BATCH_FROM=2 bin/rails products:seo_ai_generate`  
   Échantillon : `LIMIT=5 bin/rails products:seo_ai_generate`  
   Modèle : `SEO_AI_MODEL=gpt-4.1-mini`

5. **Dry-run dev**

   ```bash
   bin/rails products:seo_import[tmp/produits_seo_import.csv]
   ```

6. **Import réel dev**

   ```bash
   DRY_RUN=false bin/rails products:seo_import[tmp/produits_seo_import.csv]
   ```

7. **Vérifs dev**

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
   backup le 2805 a 15h22 : b377 
   
3. **Exporter CSV prod**

   ```bash
   heroku run 'bin/rails products:seo_export' -a a1soir-2 > produits_seo_export_prod.csv
   ```

4. **Générer les noms SEO (IA locale par batch — recommandé prod)**

   Génération **en local** à partir de `produits_seo_export_prod.csv` (données prod, pas la DB dev).

   ```bash
   rm -rf tmp/seo_ai/batches
   bin/rails products:seo_ai_prepare[produits_seo_export_prod.csv]
   BATCH_SIZE=10 SEO_AI_MAX_RETRIES=3 bin/rails products:seo_ai_generate
   SEO_AI_IMPORT_OUTPUT=produits_seo_import_prod.csv bin/rails products:seo_ai_build_import
   bin/rails products:seo_ai_validate[produits_seo_import_prod.csv]
   ```

   verif amalia

   Sans `SEO_AI_IMPORT_OUTPUT`, `build_import` écrit par défaut `tmp/produits_seo_import.csv` — adapter la validation et l’import Heroku en conséquence.

   Après `build_import`, vérifier **« handles sans résultat IA »** : viser 0 avant import prod (sinon ces SKU gardent l’ancien nom). Reprise : `FORCE=true bin/rails products:seo_ai_generate` puis `build_import` à nouveau.

   Reprise d’un batch : `BATCH_FROM=12 bin/rails products:seo_ai_generate`  
   Regénérer un batch : `FORCE=true BATCH_FROM=12 bin/rails products:seo_ai_generate`  
   Modèle : `SEO_AI_MODEL=gpt-4.1-mini` (défaut). Nécessite `OPENAI_API_KEY` en local.

   Alternative manuelle : donner `produits_seo_export_prod.csv` à l’IA → `produits_seo_import_prod.csv`

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

ok 



ancienne url à verif: 

https://a1soir.com/fr/produit/eleonora-4120?back_url=%2Ffr%2Fproduits%3Fid%255B%255D%3D47%26id%255B%255D%3D45

https://a1soir.com/fr/produit/olana-1853?back_url=%2Ffr%2Fproduits%2Feleonora-4120


https://a1soir.com/fr/produit/veste-smoking-471201-32-chale-3505?back_url=%2Ffr%2Fproduits

