# Mémo — Suivi GA4 et Google Ads

**Objet :** Ce qui est mesuré sur le site public, et ce qu’il reste à ajouter  
**Contexte :** Balise Google (GA4 + Google Ads), événements du site, KPI admin  
**Statut :** Événements implémentés ; actions Google Ads à créer

---

## Balise

GA4 (`G-3MGQ64HTFR`) et Google Ads (`AW-615893168`) sont chargés par `app/views/public/shared/_gtag.html.erb`, si le cookie `analytics_consent` vaut `yes`. Sans consentement, aucun événement ne part.

La balise déclare le Consent Mode v2 (`ad_storage`, `analytics_storage`, `ad_user_data`, `ad_personalization` à `granted`) avant les `config`, puisqu’elle n’est chargée qu’après « Accepter ».

Les événements serveur passent par le partial `public/shared/_ga4_event.html.erb` et le contrôleur Stimulus `ga4_event_controller.js`, qui appelle `gtag("event", nom, payload)`. Les payloads sont préparés dans `app/helpers/analytics_helper.rb`. Les clics sortants passent par `ga4_outbound_links_controller.js`, posé sur le `<body>` du layout public.

---

## Événements déjà envoyés

| Événement | Moment | Page |
|---|---|---|
| `view_item` | affichage d’une fiche produit | fiche produit |
| `add_to_cart` | ajout au panier | fiche produit (Turbo Stream) |
| `begin_checkout` | départ vers le paiement Stripe | panier |
| `purchase` | paiement confirmé, une fois par paiement | statut du paiement |
| `request_appointment` | demande de rendez-vous enregistrée | rendez-vous, cabine d’essayage |
| `message_send` | message de contact enregistré | contact |
| `add_to_wishlist` | produit ajouté à la cabine d’essayage | cartes produits, fiche produit (Turbo Stream) |
| `phone_call` | clic sur un lien `tel:` | tout le site public |
| `get_directions` | clic sur un lien `https://www.google.com/maps/…` | tout le site public |

`add_to_wishlist` reprend le payload de `add_to_cart`. Il n’est envoyé que si le produit est réellement ajouté (pas s’il y est déjà, indisponible ou si la cabine est pleine).

`phone_call` et `get_directions` sont détectés au clic sur n’importe quel lien correspondant, y compris les liens ajoutés plus tard. Un clic sur le numéro ne prouve pas que l’appel a eu lieu.

`request_appointment` et `message_send` sont mémorisés en session au succès du formulaire, puis rendus une seule fois sur la page de retour. Rien n’est envoyé en cas d’erreur (reCAPTCHA, validation), ni au rechargement. Le payload est vide : aucun nom, e-mail ou téléphone.

Limite : si le visiteur n’a pas accepté les cookies au moment de la page de succès, l’événement n’est pas renvoyé plus tard (même comportement que `purchase`).

---

## KPI admin

Onglet Analyses, Rendez-vous, carte « Demandes du site » : la première ligne affiche le nombre de messages de contact de la période (`messages_site` dans `Analyses::RdvStats`).

Ce chiffre vient de la table `contact_messages`, pas de Google. Il compte aussi les visiteurs qui ont refusé les cookies, donc il sera supérieur au nombre de `message_send` dans GA4.

---

## À faire côté Google

1. Déployer, puis faire un vrai rendez-vous et un vrai message, cookies acceptés.
2. GA4 : vérifier la réception (DebugView ou rapport Temps réel), puis marquer les deux événements comme **événements clés**.
3. Google Ads (après 24 à 48 h), **Objectifs → Conversions → Créer**, Site Web :
   - `request_appointment`, catégorie Prise de rendez-vous, action **principale**
   - `message_send`, catégorie Contact, action **secondaire**
   - `phone_call`, catégorie Appel téléphonique, action **secondaire**
   - `get_directions`, catégorie Itinéraire ou Prospect, action **secondaire**
   - Comptage « Une », sans valeur, fenêtre de clic 90 jours
   - `add_to_wishlist` reste dans GA4 seulement
4. `purchase` : à importer comme conversion principale avec le montant réel seulement si une campagne vise l’e-shop. Sinon, le laisser hors de Google Ads.

Vérifier que chaque action passe à l’état « Enregistrement des conversions » avant de s’en servir pour optimiser une campagne.

---

## Encore possible

- `chat_start` (facultatif) : premier message au chatbot, pour mesurer son usage. GA4 seulement.

Pas pertinents : partage WhatsApp, lien Instagram, formulaire de mensurations (clients déjà en commande).

---

## Points d’attention

- **Numéro FAQ** : corrigé (`tel:+33493451717` dans `app/views/public/pages/faq.html.erb`).
