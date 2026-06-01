
ok - fix ajouter d'autres produits from cabine qui apparait sur show 
ok - fix etiquette
ok - verifier commande pdf ok en prod 
ok - verifier en prod (produits cha etc)
ok - mettre en place stripe eshop

à surveiller:
______________

- verifier sitemap ok suite au renommage - jours semaines
- verifier flux merchant se met bien à jour aussi - jours semaines
   ok - fix group item id
- verifier produits ajoutés dans fiches
- surveiller erreurs serveur depuis ferrum et chrome ajoutés

ToDo short terme : 
_____________________


ok - passer sur ferrer pour pdf et reconstruire les pdf a la plce de wicked pdf 

ok - push prod de l'update ferrum
    etiquettes, commandes, syntehse reporting admin
ok - supprimer les var env pour format pdf etiquettes
ok - supprimer wkhtmltopdf de la prod (buildpack)
ok - verif pdf reporting stock bien protégé admin seul pas vendeur
ok - supprimer les tests ferrum

ok - upgrade ruby 3.2.2 avant, 3.3.11 apres
ok - upgrade rails 7.1.3 avant, 7.2 apres
ok - passer sur last version of heroku 22 avant, puis 24 ok, 26 pas urgent
ok - update cli heroku aussi ?
ok - upgrade puma ?

ok - verif prise de rdv ok avec mail en prod
ok - verif article sous article ok

ok - voir avec cha si elle veut un format plus pratique pour le decoupage des etiquettes ?
ok - retester notamment avec bcp tailels et couleurs en prod
ok - restester commande

ok - tableau sous article
ok - ajouter le mailer qui indiquer le remboursement fait suite a commande eshop annulé coté application
ok - fix n+1 admin 
ok - fix n+1 public


opti pdf : 
ok - images a eviter en pleine qualité
gros gain avec ca
voir avec cha si qualité image sur bon de commande ou etiquette trop faible

- voir si gc en buildpack fonctionne bien ?
- voir pour ameliorer la baseline a 630/800 mb sur heroku ?
- si necessaire passer sur un worker pour pdf ?



call 0106:

ok - dupliquer le scan de bloque large et le mettre aussi dans la navbar
ok - sur bloc large eshop : enlevé le petit 1 si expédié
ok - faire lsite de prenoms, comparer à prenom existant, indiquer prenom restant


ok - navbar sur admin et public, pouvoir cliquer en dehors de la navbar pour qu’elle se reduise, meme comportement que clique sur le bouton collapse

ok - ameliroer qualité images sur etiquettes pdf
ok - verifier video bien dupliquée quand duplication produit

ok - quid possible de chsoir les avis les plus récents plutot que plus pertiennts pour avis google 




ToDo long terme :
_________________

- partie blog : ajouter des pages seo avec l'histoire d'une cateogire et les liens vers les produits, une video pour engagemnet plus long

- mettre en place le flux merchant pour produits en boutique (code etablissement)
- remettre une campaign google ads

- essyage virtuel
- chatbot ia
- lien acheter sur insta ? fb etc ?

-  qrzing