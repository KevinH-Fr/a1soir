# Seeds de développement — PostgreSQL / jsonb mensurations.
# Ne pas lancer en production. Chargement : bin/rails db:seed

if Rails.env.development?
puts "Seeds développement (developpement_pg)…"

User.find_or_initialize_by(email: "dev@example.com").tap do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.role = "admin"
  user.save!
end

Profile.find_or_create_by!(prenom: "Eshop")
Texte.find_or_create_by!(titre: "Boutique") do |texte|
  texte.contact = "contact@example.com"
  texte.horaire = "Sur rendez-vous"
  texte.adresse = "Cannes"
end

# --- Mensurations : cas jsonb -------------------------------------------------

def seed_invitation!(email:, **attrs)
  invitation = MensurationInvitation.find_or_initialize_by(email: email)
  invitation.assign_attributes(attrs)
  invitation.save!
  invitation
end

def seed_mensuration!(invitation, **attrs)
  fiche = invitation.mensuration || invitation.build_mensuration
  fiche.assign_attributes(attrs)
  fiche.save!(validate: false)
  fiche
end

def seed_named!(klass, nom, **attrs)
  record = klass.find_or_initialize_by(nom: nom)
  record.assign_attributes(attrs)
  record.save!
  record
end

def seed_article!(commande, produit, **attrs)
  article = Article.find_or_initialize_by(commande: commande, produit: produit)
  article.assign_attributes(attrs)
  article.save!
  article
end

# 1. Lien envoyé, formulaire pas commencé
seed_invitation!(
  email: "lien.attente@example.com",
  prenom: "Léa",
  nom: "Bernard",
  token: "seed-lien-attente",
  locale: "fr",
  template: nil,
  status: "sent",
  expires_at: 7.days.from_now
)

# 2. OTP ok, brouillon femme (jsonb partiel + reprise wizard)
invitation_draft = seed_invitation!(
  email: "brouillon.femme@example.com",
  prenom: "Anna",
  nom: "Durand",
  token: "seed-brouillon-femme",
  locale: "fr",
  template: "femme",
  status: "verified",
  expires_at: 7.days.from_now
)
seed_mensuration!(
  invitation_draft,
  client: nil,
  prenom: "Anna",
  nom: "Durand",
  telephone: "0611111111",
  ville: "Cannes",
  template: "femme",
  locale: "fr",
  draft_step: "mesures.hauteur",
  measurements: {
    "hauteur" => "168",
    "hauteur_talons" => "8"
  }
)

# 3. Fiche femme complète, à traiter en admin
client_femme = Client.find_or_create_by!(mail: "fiche.femme@example.com") do |client|
  client.intitule = "Madame"
  client.prenom = "Camille"
  client.nom = "Moreau"
  client.tel = "0622222222"
  client.ville = "Nice"
  client.language = "fr"
end
invitation_femme = seed_invitation!(
  email: client_femme.mail,
  prenom: client_femme.prenom,
  nom: client_femme.nom,
  token: "seed-femme-complete",
  locale: "fr",
  template: "femme",
  status: "completed",
  client: client_femme,
  expires_at: 7.days.from_now
)
seed_mensuration!(
  invitation_femme,
  client: client_femme,
  prenom: "Camille",
  nom: "Moreau",
  telephone: "0622222222",
  adresse: "12 rue d'Antibes",
  cp: "06400",
  ville: "Cannes",
  date_evenement: 2.months.from_now.to_date,
  template: "femme",
  locale: "fr",
  draft_step: nil,
  admin_treated_at: nil,
  measurements: {
    "hauteur" => "168",
    "hauteur_talons" => "8",
    "taille_robe_marque" => "38",
    "taille_soutien_gorge" => "90D",
    "taille_pantalon_jupe_marque" => "38",
    "taille_veste_chemisier" => "38",
    "preference_forme_robe" => "sirène, décolleté bateau"
  }
)

# 4. Fiche homme complète (jsonb dense), déjà traitée
client_homme = Client.find_or_create_by!(mail: "fiche.homme@example.com") do |client|
  client.intitule = "Monsieur"
  client.prenom = "Jean"
  client.nom = "Martin"
  client.tel = "0633333333"
  client.ville = "Cannes"
  client.language = "fr"
end
invitation_homme = seed_invitation!(
  email: client_homme.mail,
  prenom: client_homme.prenom,
  nom: client_homme.nom,
  token: "seed-homme-complete",
  locale: "fr",
  template: "homme",
  status: "completed",
  client: client_homme,
  expires_at: 7.days.from_now
)
seed_mensuration!(
  invitation_homme,
  client: client_homme,
  prenom: "Jean",
  nom: "Martin",
  telephone: "0633333333",
  adresse: "3 boulevard de la Croisette",
  cp: "06400",
  ville: "Cannes",
  date_evenement: 6.weeks.from_now.to_date,
  template: "homme",
  locale: "fr",
  draft_step: nil,
  admin_treated_at: 1.day.ago,
  measurements: {
    "taille_veste" => "50",
    "taille_chemise" => "41",
    "coupe_chemise" => "slim",
    "taille_pantalon_marque" => "42",
    "pointure" => "43",
    "hauteur" => "182",
    "tour_cou" => "40",
    "largeur_epaules" => "48",
    "tour_poitrine" => "102",
    "tour_taille" => "88",
    "tour_taille_ceinture" => "86",
    "tour_hanches" => "100",
    "tour_hanches_pantalon" => "98",
    "longueur_bras_ext" => "64",
    "longueur_jambe_ext" => "108",
    "longueur_jambe_int" => "82"
  }
)

# 5. Invitation EN, homme, jsonb partiel (tailles seulement)
invitation_en = seed_invitation!(
  email: "draft.en@example.com",
  prenom: "James",
  nom: "Cole",
  token: "seed-draft-en",
  locale: "en",
  template: "homme",
  status: "verified",
  expires_at: 7.days.from_now
)
seed_mensuration!(
  invitation_en,
  prenom: "James",
  nom: "Cole",
  template: "homme",
  locale: "en",
  draft_step: "tailles",
  measurements: {
    "taille_veste" => "52",
    "taille_chemise" => "42",
    "coupe_chemise" => "classique",
    "pointure" => "44"
  }
)

# --- Boutique : catalogue + commandes ---------------------------------------

AdminParameter.first || AdminParameter.create!(
  tx_tva: 20,
  coef_prix_achat_vente: 2.2,
  coef_longue_duree: 2,
  duree_rdv: 60
)

%w[Découverte Essayage Retouche].each do |code|
  TypeRdv.find_or_create_by!(code: code) { |t| t.duree_base_minutes = 60 }
end

profile_boutique = Profile.find_or_create_by!(prenom: "Marie", nom: "Boutique")
profile_eshop = Profile.find_by!(prenom: "Eshop")

fournisseur = seed_named!(Fournisseur, "Seed Atelier", tel: "0493000000", mail: "atelier@example.com")
noir = seed_named!(Couleur, "noir", couleur_code: "#111111")
ivoire = seed_named!(Couleur, "ivoire", couleur_code: "#FFFFF0")
bleu = seed_named!(Couleur, "bleu nuit", couleur_code: "#191970")
t38 = seed_named!(Taille, "38")
t50 = seed_named!(Taille, "50")
t41 = seed_named!(Taille, "41")

type_robe = seed_named!(TypeProduit, "robe")
type_veste = seed_named!(TypeProduit, "veste")
type_chemise = seed_named!(TypeProduit, "chemise")
type_pantalon = seed_named!(TypeProduit, "pantalon")

cat_robes = CategorieProduit.find_or_create_by!(nom: "robes de soirée")
cat_smokings = CategorieProduit.find_or_create_by!(nom: "smokings")
cat_accessoires = CategorieProduit.find_or_create_by!(nom: "accessoires")
cat_services = CategorieProduit.find_or_initialize_by(nom: "retouches")
cat_services.service = true
cat_services.save!

# Pas de QR Cloudinary sur des données de seed.
Produit.skip_callback(:create, :after, :generate_qr)
Commande.skip_callback(:create, :after, :generate_qr)

robe = seed_named!(
  Produit, "Robe sirène ivoire",
  description: "Robe de soirée sirène, crêpe ivoire.",
  prixlocation: 250, prixvente: 890, prixachat: 320,
  caution: 800, quantite: 1, actif: true, eshop: true,
  coup_de_coeur: true, coup_de_coeur_position: 1,
  type_produit: type_robe, couleur: ivoire, taille: t38,
  fournisseur: fournisseur, reffrs: "SEED-ROBE-38"
)
smoking = seed_named!(
  Produit, "Smoking noir 50",
  description: "Smoking 2 pièces, laine noire.",
  prixlocation: 180, prixvente: 690, prixachat: 250,
  caution: 630, quantite: 1, actif: true, eshop: true,
  type_produit: type_veste, couleur: noir, taille: t50,
  fournisseur: fournisseur, reffrs: "SEED-SMOK-50"
)
chemise = seed_named!(
  Produit, "Chemise plastron blanche 41",
  description: "Chemise smoking, col cassé.",
  prixlocation: 25, prixvente: 89, prixachat: 28,
  caution: 80, quantite: 3, actif: true, eshop: true,
  type_produit: type_chemise, couleur: ivoire, taille: t41,
  fournisseur: fournisseur, reffrs: "SEED-CHEM-41"
)
pantalon = seed_named!(
  Produit, "Pantalon smoking noir 50",
  description: "Pantalon de smoking, galon satin.",
  prixlocation: 40, prixvente: 120, prixachat: 45,
  caution: 140, quantite: 2, actif: true, eshop: true,
  type_produit: type_pantalon, couleur: noir, taille: t50,
  fournisseur: fournisseur, reffrs: "SEED-PANT-50"
)
noeud = seed_named!(
  Produit, "Nœud papillon bleu nuit",
  description: "Nœud papillon soie, à nouer.",
  prixlocation: 15, prixvente: 45, prixachat: 12,
  caution: 50, quantite: 5, actif: true, eshop: true,
  couleur: bleu, fournisseur: fournisseur, reffrs: "SEED-NP-BLEU"
)
retouche = seed_named!(
  Produit, "Retouche ourlet",
  description: "Ourlet pantalon ou robe.",
  prixvente: 35, prixlocation: 0, quantite: 1,
  actif: true, eshop: false, reffrs: "SEED-RET-OURLET"
)

{
  robe => cat_robes,
  smoking => cat_smokings,
  chemise => cat_smokings,
  pantalon => cat_smokings,
  noeud => cat_accessoires,
  retouche => cat_services
}.each do |produit, cat|
  produit.categorie_produits << cat unless produit.categorie_produits.exists?(id: cat.id)
end

client_devis = Client.find_or_create_by!(mail: "devis.dupont@example.com") do |client|
  client.intitule = "Madame"
  client.prenom = "Sophie"
  client.nom = "Dupont"
  client.tel = "0644444444"
  client.ville = "Antibes"
  client.propart = "particulier"
  client.language = "fr"
end

# Location mariage — robe, à retirer
cmd_loc = Commande.find_or_initialize_by(nom: "Seed location mariage Moreau")
cmd_loc.assign_attributes(
  client: client_femme, profile: profile_boutique, montant: 250,
  devis: false, typeevent: "mariage", type_locvente: "location",
  dateevent: 2.months.from_now.to_date,
  debutloc: 2.months.from_now.to_date - 2.days,
  finloc: 2.months.from_now.to_date + 2.days,
  commentaires: "Seed — location robe"
)
cmd_loc.save!
cmd_loc.update!(statutarticles: "non-retiré")
seed_article!(
  cmd_loc, robe,
  quantite: 1, prix: 250, total: 250, locvente: "location",
  caution: 800, totalcaution: 800
)

# Location Cannes — smoking + chemise, retiré, acompte
cmd_cannes = Commande.find_or_initialize_by(nom: "Seed location Cannes Martin")
cmd_cannes.assign_attributes(
  client: client_homme, profile: profile_boutique, montant: 205,
  devis: false, typeevent: "festival de Cannes", type_locvente: "location",
  dateevent: 3.weeks.from_now.to_date,
  debutloc: 3.weeks.from_now.to_date - 1.day,
  finloc: 3.weeks.from_now.to_date + 2.days,
  commentaires: "Seed — smoking + chemise"
)
cmd_cannes.save!
cmd_cannes.update!(statutarticles: "retiré")
seed_article!(
  cmd_cannes, smoking,
  quantite: 1, prix: 180, total: 180, locvente: "location",
  caution: 630, totalcaution: 630
)
seed_article!(
  cmd_cannes, chemise,
  quantite: 1, prix: 25, total: 25, locvente: "location",
  caution: 80, totalcaution: 80
)
PaiementRecu.find_or_create_by!(commande: cmd_cannes, typepaiement: "prix", montant: 100) do |p|
  p.moyen = "carte bleue"
  p.custom_date = Date.current
end

# Vente nœud + retouche, rendu
cmd_vente = Commande.find_or_initialize_by(nom: "Seed vente noeud Dupont")
cmd_vente.assign_attributes(
  client: client_devis, profile: profile_boutique, montant: 80,
  devis: false, typeevent: "soirée", type_locvente: "vente",
  dateevent: 1.week.ago.to_date, commentaires: "Seed — vente + retouche"
)
cmd_vente.save!
cmd_vente.update!(statutarticles: "rendu")
seed_article!(cmd_vente, noeud, quantite: 1, prix: 45, total: 45, locvente: "vente")
seed_article!(cmd_vente, retouche, quantite: 1, prix: 35, total: 35, locvente: "vente")
PaiementRecu.find_or_create_by!(commande: cmd_vente, typepaiement: "prix", montant: 80) do |p|
  p.moyen = "espèces"
  p.custom_date = 1.week.ago.to_date
end

# Devis smoking (pas encore confirmé)
cmd_devis = Commande.find_or_initialize_by(nom: "Seed devis smoking Dupont")
cmd_devis.assign_attributes(
  client: client_devis, profile: profile_boutique, montant: 235,
  devis: true, typeevent: "mariage", type_locvente: "location",
  dateevent: 4.months.from_now.to_date,
  debutloc: 4.months.from_now.to_date - 2.days,
  finloc: 4.months.from_now.to_date + 2.days,
  commentaires: "Seed — devis"
)
cmd_devis.save!
seed_article!(
  cmd_devis, smoking,
  quantite: 1, prix: 180, total: 180, locvente: "location",
  caution: 630, totalcaution: 630
)
seed_article!(
  cmd_devis, pantalon,
  quantite: 1, prix: 40, total: 40, locvente: "location",
  caution: 140, totalcaution: 140
)
seed_article!(
  cmd_devis, noeud,
  quantite: 1, prix: 15, total: 15, locvente: "location",
  caution: 50, totalcaution: 50
)

# Petite commande e-shop
cmd_shop = Commande.find_or_initialize_by(nom: "Seed eshop chemise")
cmd_shop.assign_attributes(
  client: client_homme, profile: profile_eshop, montant: 89,
  devis: false, typeevent: "divers", type_locvente: "vente",
  eshop: true, commentaires: "Seed — e-shop"
)
cmd_shop.save!
seed_article!(cmd_shop, chemise, quantite: 1, prix: 89, total: 89, locvente: "vente")

puts "OK — admin: dev@example.com / password"
puts "  /fr/m/seed-lien-attente     invitation sent"
puts "  /fr/m/seed-brouillon-femme  brouillon femme"
puts "  /fr/m/seed-femme-complete   femme jsonb complet"
puts "  /fr/m/seed-homme-complete   homme jsonb complet (traité)"
puts "  /en/m/seed-draft-en         brouillon EN"
puts "  catalogue: 6 produits, 5 commandes (location / Cannes / vente / devis / e-shop)"
end
