# Mémo — Catalogue costumes d’époque et déguisements

**Objet :** Séparer les costumes d’époque et les déguisements des tenues de mariage et de soirée  
**Où :** Admin, fiche produit, bloc Publication  
**Statut :** Implémenté

---

## Où est le choix de catalogue

Ouvrir un produit dans l’admin. Dans la colonne de droite, section **Publication**, sous les cases Actif et E-shop, deux boutons radio **Catalogue**. Le choix par défaut est **Tenues de mariage et soirée**.

- **Tenues de mariage et soirée** — valeur de tous les produits déjà en ligne
- **Costumes d'époque et déguisements**

Ce menu n’est pas la catégorie « costume et déguisement » (id 2), ni le type de produit, ni les cases **Catégories**.

Le même mot **Catalogue** existe aussi en filtre de la liste admin des produits (Tous / Tenues de mariage et soirée / Costumes d'époque et déguisements). Il sert à retrouver les fiches, il ne classe pas le produit.

---

## Ce qu’il ne faut pas faire

Ne pas ranger les époques et les personnages dans **Cat. produits**, ni cocher la catégorie « costume et déguisements » pour alimenter la nouvelle page.

Cette catégorie reste une catégorie du catalogue mariage. Tant que le bouton radio reste sur « Tenues de mariage et soirée », le produit reste sur `/produits`, avec ses catégories actuelles.

---

## Structure

Un seul modèle produit. Quatre champs se côtoient.

| Champ | Où sur la fiche | Rôle |
|---|---|---|
| Type de produit | Général | Une valeur : robe, costume, accessoire… Inchangé. |
| Catégories | Publication, si catalogue Tenues de mariage et soirée | Cases du mariage : robes de mariée, smokings, « costume et déguisements », etc. |
| Catalogue | Publication, sous Actif et E-shop | Bascule entre les deux métiers. |
| Rubriques | Publication, si catalogue Costumes d'époque et déguisements | Époque, personnage ou univers. Plusieurs cases possibles. |

Les rubriques se gèrent à part : raccourci **Rubriques costumes**, à côté de **Cat. produits**. Champs : nom, groupe, position. Le groupe est un texte libre (Époque, Personnage, Univers, ou un nom créé là).

Rubriques de départ, à renommer, déplacer ou supprimer :

- Époque : Renaissance, XVIIIe siècle, Époque napoléonienne, Belle Époque, Années 1920-1930, Années 1950-1960, Années 1970-1980
- Personnage : Marquis et marquise, Pirate, Conte et féerie
- Univers : Carnaval, Bal masqué

« Sur mesure » reste un texte de la page d’introduction, pas une rubrique.

---

## Exemples

**Smoking de cérémonie**

- Catalogue : Tenues de mariage et soirée
- Catégories : costume, smokings
- Rubriques : aucune
- Page : `/produits`

**Habit de marquise**

- Catalogue : Costumes d'époque et déguisements
- Catégories : aucune (retirées à l’enregistrement)
- Rubriques : Marquis et marquise et XVIIIe siècle
- Page : `/produits_costumes_deguisements`
- Il sort dans les deux thèmes. Cocher un thème montre les produits qui l’ont, même s’ils en ont d’autres.

Le type de produit peut rester « costume » dans les deux cas. Il ne décide pas de la page.

---

## Enregistrement

Changer le bouton radio **Catalogue** demande confirmation. Annuler remet la valeur précédente. Confirmer masque un bloc et affiche l’autre, sans enregistrer la fiche.

Choisir **Costumes d'époque et déguisements** puis confirmer masque les cases Catégories et affiche les rubriques. À l’enregistrement, les catégories mariage du produit sont vidées, y compris « costume et déguisements ».

Revenir à **Tenues de mariage et soirée** vide les rubriques et réaffiche les catégories.

Aucun produit existant n’est reclassé tout seul. Pour sortir une pièce du catalogue mariage : ouvrir la fiche, Catalogue = Costumes d'époque et déguisements, cocher les rubriques, enregistrer.

---

## Pages publiques

- Bouton sur la carte Costumes d’époque de **Autres activités** → `/fr/costumes-depoque`
- Cette page liste les rubriques des produits **Costumes d'époque et déguisements** en ligne et en stock, regroupées par le groupe saisi dans l’admin. Une rubrique sans pièce en stock n’a pas de bouton. Tant qu’aucune pièce n’est passée sur ce catalogue, seuls le texte, le bouton « toute la collection » et les guides s’affichent.
- La liste de périodes sur la carte **Autres activités** reste un texte de présentation, dont « Costumes sur mesure ». Elle ne lit pas les rubriques.
- Liste → `/fr/produits_costumes_deguisements`
- Filtres de cette liste : Thème (les rubriques présentes sur des pièces en stock), Taille, Couleur
- Les guides Carnaval et Marquis et marquise utilisent aussi le catalogue Costumes d'époque et déguisements, puis le nom exact de la rubrique pour n’afficher que ce thème. Un renommage de cette rubrique dans l’admin demande le même renommage dans la config du guide.
- `/produits`, les catégories et les collections ne changent pas de présentation. Un costume n’y figure pas. Une catégorie ou un type qui n’existe que par ces pièces n’apparaît plus dans leurs filtres.
- La carte « Costumes » de l’accueil continue de pointer vers le costume de cérémonie.

---

## Flux Google et Meta

Les pièces **Costumes d'époque et déguisements** restent hors du flux. `GoogleMerchant::FeedBuilder` et l’inventaire local ne prennent que le catalogue **Tenues de mariage et soirée**. Le flux Meta reprend le même XML.

Le flux sert aux annonces Shopping : pièces en e-shop, avec photo et prix de vente. Une pièce costumes n’a plus de catégorie mariage, et la catégorie « costume » de ce flux désigne le costume homme et le smoking. Les mélanger mettrait des habits d’époque à côté des robes de mariée.

Des annonces pour les costumes d’époque demanderaient un second flux, pas celui-ci.

---

## Checklist du 6 novembre 2026

À cocher à la main. Partie A en local, avant le push. Partie B demain, après le déploiement.

Les seeds locaux ont déjà quelques pièces costumes. En production, aucune fiche n’est reclassée toute seule : la liste costumes reste vide tant qu’une pièce n’est pas passée à la main.

Pièce témoin à préparer en local : une tenue de mariage connue (noter son nom, son type, ses catégories) et une pièce seed costumes (marquis / XVIIIe).

---

### A. Local, avant le push — 6 novembre

**Admin, bascule de catalogue**

- [ ] Nouveau produit : radio par défaut **Tenues de mariage et soirée**. Les catégories sont visibles, les rubriques sont cachées.
- [ ] Passer le radio sur **Costumes d'époque et déguisements**. Une confirmation s’affiche. Annuler : le radio revient, rien n’est enregistré.
- [ ] Confirmer : les catégories se cachent, les rubriques s’affichent. La fiche n’est toujours pas enregistrée.
- [ ] Enregistrer. Rouvrir la fiche : plus de catégories mariage, y compris « costume et déguisement ». Le type de produit est inchangé.
- [ ] La carte admin et le détail replié affichent **Costumes d'époque et déguisements**, plus les badges de rubriques cochées.
- [ ] Revenir au radio **Tenues de mariage et soirée**. Annuler laisse la fiche en costumes. Confirmer puis enregistrer : les rubriques sont vidées, les catégories réapparaissent et sont à recocher. Le type est toujours le même.
- [ ] La catégorie « costume et déguisement » est toujours dans **Cat. produits**. Ne pas la supprimer. La catégorie cérémonie `costume` est toujours là.

**Admin, rubriques et filtre de liste**

- [ ] **Rubriques costumes** (à côté de Cat. produits) : liste, création, modification. Champs nom, groupe, position. Le nom garde ses majuscules et « XVIIIe ».
- [ ] Deux rubriques cochées sur une même fiche : les deux badges sont là après enregistrement.
- [ ] Une rubrique liée à un produit ne se supprime pas. Une rubrique sans produit se supprime.
- [ ] Filtre **Catalogue** de la liste admin : Tous / Tenues de mariage et soirée / Costumes d'époque et déguisements. Il retrouve les fiches, il ne les reclasse pas.
- [ ] Les autres filtres admin (catégorie, type, taille, couleur, statut) marchent encore sur la liste mariage.

**Public, les deux listes et leurs filtres**

- [ ] `/fr/produits` : la pièce costumes n’y est pas. La tenue témoin y est, avec ses catégories.
- [ ] Filtres mariage toujours là : catégorie, type, taille, couleur, prix, vente/location. En combiner deux, puis tout réinitialiser. La pagination charge la suite.
- [ ] `/fr/produits_costumes_deguisements` : la tenue mariage n’y est pas. La pièce costumes y est.
- [ ] Filtres de cette liste : seulement Thème, Taille, Couleur. Pas de catégorie, type, prix, vente/location, promo.
- [ ] Cocher un thème : la pièce qui a cette rubrique sort, même si elle en a une autre. Cocher l’autre rubrique de la même pièce : elle sort aussi.
- [ ] Un thème sans pièce garde les menus Thème, Taille et Couleur.
- [ ] Taille + couleur ensemble, puis pastilles actives, puis reset : retour à la liste costumes complète.
- [ ] La barre de recherche garde sa largeur sur les deux listes.
- [ ] `/en/produits` et `/en/produits_costumes_deguisements` ouvrent les mêmes listes en anglais.

**Public, passage d’un catalogue à l’autre**

- [ ] Depuis `/fr/produits` avec un filtre, ouvrir une fiche, revenir : même liste, mêmes filtres.
- [ ] Depuis la liste costumes avec un thème, ouvrir une fiche, revenir : liste costumes, même thème.
- [ ] Ouvrir une fiche costumes par son URL directe, puis revenir : la liste costumes, pas `/produits`.
- [ ] Les produits similaires d’une fiche restent dans son catalogue.
- [ ] Une collection et une catégorie mariage n’affichent pas la pièce costumes. Leurs filtres ne proposent pas une catégorie ou un type qui n’existerait plus que par cette pièce.

**Recherche — SQLite, sur les deux listes**

Chaque mot doit être trouvé. L’ordre est libre. Les accents passent dans les deux sens. Colonnes : nom, description, catégorie, type, couleur, taille, nom de rubrique. La recherche reste dans le catalogue de la page.

- [ ] `robe soiree` et `soiree robe` retrouvent la même tenue.
- [ ] `robe` et `robé` retrouvent la même pièce. Idem `ceremonie` / `cérémonie` et `coeur` / `cœur`.
- [ ] `robe chapeau` ne sort pas une robe dont le texte n’a pas « chapeau ».
- [ ] Une recherche sur `/fr/produits` ne montre pas la pièce costumes. La même recherche sur la liste costumes ne montre pas la tenue de mariage.
- [ ] `XVIIIe` et `marquis` sur la liste costumes retrouvent les pièces de ces rubriques.
- [ ] `100%` reste le caractère pour cent. Il ne devient pas un joker.

**Pages, guides, accueil, cabine**

- [ ] Autres activités : le bouton mène à `/fr/costumes-depoque`. La liste de périodes de la carte reste du texte, dont « Costumes sur mesure ».
- [ ] La landing groupe les rubriques comme dans l’admin (Époque, Personnage, Univers, ou un groupe créé à la main). Une rubrique sans pièce en stock et en e-shop n’a pas de bouton.
- [ ] « À lire aussi » sur la landing montre les six guides costumes. `/fr/guides` (« Tous les guides ») ne les liste pas.
- [ ] `/fr/guides/costume-epoque-mariage-theme` redirige vers `/fr/guides/costumes-epoque-histoire-mode`.
- [ ] `/fr/guides/costume-carnaval-nice` et `/fr/guides/costume-marquis-marquise` n’affichent que les produits de la rubrique du même nom.
- [ ] La carte « Costumes » de l’accueil mène encore au costume de cérémonie, pas à la liste costumes.
- [ ] Coups de cœur : accueil, collections, catégories. Que des tenues de mariage et soirée.
- [ ] Liste costumes : les cartes n’ouvrent pas le mode cabine. Sur la fiche, le bouton cabine est là.
- [ ] Depuis la cabine, « voir les produits » va vers `/produits?from_cabine=true`, le catalogue mariage.

**Images Festival, en local**

- [ ] `/fr/festival-de-cannes` et `/en/festival-de-cannes` : les visuels s’affichent.
- [ ] Le HTML utilise `festival-cannes-2026-…` (`offre-fr-1`, `offre-fr-2`, `offre-en-1`, `offre-en-2`, `header-1`, `header-2`). Il ne contient plus `WhatsApp_Image`.

---

### B. Production, après le déploiement — 7 novembre

La colonne `catalogue` n’existe pas encore. Les deux migrations tournent avec le code. Toutes les fiches passent à **Tenues de mariage et soirée**. Aucune ne devient un costume d’époque.

**Juste après le déploiement**

- [ ] L’admin s’ouvre. Une fiche existante a le radio **Tenues de mariage et soirée**, ses catégories, son type.
- [ ] `/fr/produits` et `/en/produits` montrent les mêmes tenues qu’avant. Les filtres catégorie, type, taille, couleur, prix, vente/location répondent.
- [ ] `/fr/produits_costumes_deguisements` n’a pas de produits. La landing `/fr/costumes-depoque` n’a pas de boutons de rubrique : texte, lien vers la liste, guides.
- [ ] La catégorie « costume et déguisement » est toujours là. Ne pas la supprimer.
- [ ] La carte « Costumes » de l’accueil mène encore au costume de cérémonie.
- [ ] `/fr/guides/costume-epoque-mariage-theme` redirige vers le guide histoire et mode.
- [ ] « Tous les guides » ne liste pas les guides costumes. La landing les montre dans « À lire aussi ».
- [ ] Sitemap : `/fr/costumes-depoque` et `/fr/produits_costumes_deguisements` (et les URLs `/en/`).

**Recherche — PostgreSQL, à refaire**

Le pliage des accents en prod passe par `translate`, pas par la fonction SQLite du local. Refaire sur `/fr/produits`, puis sur la liste costumes une fois une pièce reclassée.

- [ ] `robe` et `robé`. `ceremonie` et `cérémonie`. `coeur` et `cœur`.
- [ ] `robe soiree` et `soiree robe` : même résultat.
- [ ] Un mot absent exclut la pièce.
- [ ] `100%` ne devient pas un joker.
- [ ] Après avoir passé une pièce en costumes : elle disparaît de `/produits` et de sa recherche, et elle apparaît sur la liste costumes.

**Une pièce passée à la main**

- [ ] Ouvrir une fiche, radio **Costumes d'époque et déguisements**, confirmer, cocher une ou deux rubriques, enregistrer.
- [ ] Les catégories mariage de cette fiche sont vidées. Le type est inchangé.
- [ ] Elle sort sur `/fr/produits_costumes_deguisements`. Les filtres Thème, Taille, Couleur la retrouvent. La landing affiche les rubriques de cette pièce, groupées comme dans l’admin.
- [ ] Elle n’est plus sur `/produits`, ni dans une collection, ni dans une catégorie, ni dans les coups de cœur.
- [ ] Revenir au catalogue mariage, enregistrer : les rubriques sont vidées, les catégories sont à recocher, la pièce revient sur `/produits`.

**Flux et Festival**

- [ ] `https://a1soir.com/google_merchant_feed.xml` et `https://a1soir.com/meta_catalog_feed.xml` contiennent les tenues de mariage et soirée. La pièce passée en costumes n’y est pas.
- [ ] `/fr/festival-de-cannes` et `/en/festival-de-cannes` : les visuels s’affichent.
- [ ] Adresses `festival-cannes-2026-offre-fr-1`, `offre-fr-2`, `offre-en-1`, `offre-en-2`, `header-1`, `header-2`. Le HTML ne contient plus `WhatsApp_Image`.
