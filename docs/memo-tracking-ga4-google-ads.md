# Mémo — Suivi GA4 et Google Ads

**Statut au 14 octobre 2026.** Balise déjà sur le site, après « Accepter » : GA4 `G-3MGQ64HTFR` et Ads `AW-615893168`.

Réglages de chaque conversion Ads : comptage **Une**, fenêtre de clic **90 jours**, **sans valeur**. `purchase` est la seule avec le montant réel. Avant de s’en servir dans une campagne, l’action doit être à **Enregistrement des conversions**.

Contact et panier comptent un chargement de page. Un clic interne (Turbo) peut ne pas compter.

| Action | GA4 | Google Ads | Rôle | À faire |
|---|---|---|---|---|
| Vue Contact | Confirmée | Créée. **L'URL contient** `contact` | Secondaire | Vérifier les réglages |
| Vue panier (`visit cart`) | Pas d’événement nommé | Créée, visible | Secondaire | Vérifier les réglages |
| `purchase` | Confirmée | À créer | Principale | Événement clé. Valeur = montant |
| `request_appointment` | Confirmée | À créer | Principale | Événement clé. Catégorie Prise de rendez-vous |
| `add_to_cart` | Confirmée | À créer | Secondaire | Événement clé |
| `begin_checkout` | Confirmée | À créer | Secondaire | Événement clé |
| `phone_call` | Confirmée | À créer | Secondaire | Événement clé. Catégorie Appel téléphonique |
| `add_to_wishlist` | Confirmée | À créer | Secondaire | Événement clé. Catégorie liste de souhaits, ou Autre |
| `view_item` | Confirmée | Rien à créer | — | — |
| `message_send` | Envoyé, pas revu | Rien pour l’instant | — | — |
| `get_directions` | Envoyé, pas revu | Rien pour l’instant | — | — |
