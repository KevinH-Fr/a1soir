### Optimisation Puma sur A1soir

#### Situation actuelle

Ton dyno Heroku est :

```txt
Standard-2X
1 Go RAM
```

Ton Puma utilise actuellement :

```txt
WEB_CONCURRENCY=4
RAILS_MAX_THREADS=5
```

Donc :

```txt
4 workers Puma
× 5 threads
= jusqu'à 20 requêtes simultanées
```

Comme chaque worker charge une copie complète de Rails en mémoire, cela explique probablement pourquoi ton dyno tourne souvent à **80% de RAM**.

---

#### Optimisation proposée

Forcer Puma à :

```txt
WEB_CONCURRENCY=1
RAILS_MAX_THREADS=5
```

Commande :

```bash
heroku config:set WEB_CONCURRENCY=1 RAILS_MAX_THREADS=5 -a a1soir-2
heroku restart -a a1soir-2
```

---

#### Bénéfices attendus

* Réduction importante de la RAM utilisée.
* Moins de risque de :

  * R14 (Memory quota exceeded)
  * H27 (Client Request Interrupted)
* Moins de pression sur le dyno.
* Aucun changement dans le code de l'application.

---

#### Risque

Le risque n'est pas fonctionnel (l'app continue de fonctionner).

Le seul risque est de réduire la capacité maximale simultanée :

```txt
Avant : 20 requêtes simultanées
Après : 5 requêtes simultanées
```

Mais avec :

```txt
20 à 50 visiteurs par jour
```

cela reste largement suffisant.

---

#### Retour arrière

Si besoin :

```bash
heroku config:unset WEB_CONCURRENCY RAILS_MAX_THREADS -a a1soir-2
heroku restart -a a1soir-2
```

ou compromis :

```bash
heroku config:set WEB_CONCURRENCY=2 RAILS_MAX_THREADS=5 -a a1soir-2
```

---

#### Priorité

C'est probablement l'optimisation **la plus simple, la moins risquée et la plus rentable** à tester avant d'ajouter un worker dédié ou de changer de plan Heroku.


##### Verif 

heroku run rails runner 'puts "RAILS_MAX_THREADS=#{ENV.fetch("RAILS_MAX_THREADS") { 5 }}"; puts "WEB_CONCURRENCY=#{ENV.fetch("WEB_CONCURRENCY") { Concurrent.physical_processor_count }}"' -a a1soir-2

apres modif je suis a 285 mb environ sur l'app heroku sans actions, bcp mieux !!
