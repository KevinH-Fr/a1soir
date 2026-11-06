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

## À vérifier après la mise en production

Aucun produit n’est reclassé tout seul. Tant qu’une fiche n’a pas été passée à la main sur **Costumes d'époque et déguisements**, elle reste sur `/produits`.

**Catalogue**

- Les deux radios s’affichent. Le défaut des fiches déjà en ligne est **Tenues de mariage et soirée**.
- Changer de radio demande confirmation. Annuler ne change rien et n’enregistre pas.
- Enregistrer vers Costumes d'époque et déguisements vide les catégories. L’inverse vide les rubriques.
- La fiche admin, y compris le détail replié, affiche le catalogue. Une pièce costumes affiche aussi ses rubriques.
- La catégorie « costume et déguisement » est toujours là. Ne pas la supprimer.
- La carte « Costumes » de l’accueil mène encore au costume de cérémonie.

**Listes**

- `/fr/produits` et `/en/produits` : mêmes filtres qu’avant (catégorie, type, taille, couleur, prix, vente/location). Aucun produit costumes.
- `/fr/produits_costumes_deguisements` et la version anglaise : seulement thème, taille, couleur. Aucune tenue de mariage.
- Un filtre thème sans résultat garde les menus thème, taille et couleur de ce catalogue.
- La barre de recherche reste limitée en largeur sur les deux listes.
- Le retour d’une fiche ouverte depuis une liste ramène à cette liste, filtres compris. Une fiche costumes ouverte directement ramène à la liste costumes.
- Les coups de cœur de l’accueil, des collections et des catégories restent des tenues de mariage et soirée.
- Les flux Google et Meta ne contiennent pas les pièces costumes.

**Pages et guides**

- Autres activités : le bouton « Voir les costumes et déguisements » est visible et mène à `/costumes-depoque`.
- Cette landing affiche les rubriques des pièces costumes en ligne et en stock, groupées comme dans l’admin. Le bloc « À lire aussi » montre les guides costumes. « Tous les guides » ne les liste pas.
- `/fr/guides/costume-epoque-mariage-theme` redirige vers `/fr/guides/costumes-epoque-histoire-mode`.
- Les guides Carnaval et Marquis n’affichent que les produits de la rubrique du même nom.

**Cabine**

- Depuis la liste costumes, les cartes n’ouvrent pas le mode cabine.
- Sur la fiche d’une pièce costumes, le bouton cabine est toujours là.

**Recherche, sur `/produits` et sur `/produits_costumes_deguisements`**

Chaque mot doit être trouvé. L’ordre ne compte pas. Les accents sont ignorés dans les deux sens (`robe` = `robé`, `ceremonie` = `cérémonie`, `coeur` = `cœur`). La recherche regarde le nom, la description, la catégorie, le type, la couleur, la taille et le nom de rubrique. Elle reste dans le catalogue de la page.

- `robe soiree` et `soiree robe` retrouvent la même tenue.
- `robe chapeau` ne sort pas une robe qui n’a pas « chapeau ».
- Une recherche sur `/produits` ne montre pas un costume d’époque, et l’inverse.
- `XVIIIe` ou `marquis` sur la liste costumes retrouve les pièces de ces rubriques.
- `100%` reste le caractère pour cent, pas un joker.

**Images Festival**

- `/fr/festival-de-cannes` et `/en/festival-de-cannes` : les visuels s’affichent.
- Les adresses utilisent `festival-cannes-2026-offre-fr-1`, `offre-fr-2`, `offre-en-1`, `offre-en-2`, `header-1`, `header-2`.
- Le HTML ne contient plus `WhatsApp_Image`.
