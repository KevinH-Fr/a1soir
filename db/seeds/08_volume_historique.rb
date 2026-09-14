# frozen_string_literal: true

# Volume historique : ~1–3 commandes boutique / jour + ~1 vente e-shop / 3 jours
# sur les 90 derniers jours (idempotent via noms stables).
Seeds::Helpers.log("08", "Volume commandes 3 mois (boutique + e-shop)")

days = 90
rng = Random.new(2026_03_14)

profile_marie = Profile.find_by!(prenom: "Marie", nom: "Dupont")
profile_paul = Profile.find_by!(prenom: "Paul", nom: "Martin")
profile_eshop = Profile.for_eshop_commandes
profiles_boutique = [profile_marie, profile_paul]

client_sophie = Client.find_by!(mail: "client@dev.a1soir.local")
client_martin = Client.find_by!(mail: "martin@dev.a1soir.local")

extra_clients = [
  ["Leroy", "Camille", "camille.leroy@dev.a1soir.local", "0600000010"],
  ["Petit", "Julie", "julie.petit@dev.a1soir.local", "0600000011"],
  ["Moreau", "Antoine", "antoine.moreau@dev.a1soir.local", "0600000012"],
  ["Garcia", "Nina", "nina.garcia@dev.a1soir.local", "0600000013"],
  ["Roux", "Hugo", "hugo.roux@dev.a1soir.local", "0600000014"]
].map do |nom, prenom, mail, tel|
  Client.find_or_create_by!(mail: mail) do |c|
    c.nom = nom
    c.prenom = prenom
    c.propart = "particulier"
    c.intitule = Client::INTITULE_OPTIONS.first
    c.tel = tel
  end
end

clients = [client_sophie, client_martin] + extra_clients
produits = Produit.where("reffrs LIKE ?", "SEED-%").to_a
raise "[seeds] Aucun produit SEED-* — lancer 05_catalogue avant 08" if produits.empty?

produits_eshop = produits.select(&:eshop)
produits_eshop = produits if produits_eshop.empty?

moyens = ["carte bleue", "espèces", "chèque", "virement"].freeze
statuts = ["retiré", "non-retiré", "rendu"].freeze
types_commande = ["vente", "location", "mixte"].freeze

build_articles = lambda do |type_locvente|
  count = rng.rand(1..2)
  produits.sample(count, random: rng).map do |produit|
    locvente =
      case type_locvente
      when "vente" then "vente"
      when "location" then "location"
      else rng.rand < 0.5 ? "vente" : "location"
      end

    base = locvente == "vente" ? (produit.prixvente || 80) : (produit.prixlocation || 40)
    prix = [base.to_i + rng.rand(-15..20), 10].max
    quantite = rng.rand(1..2)

    {
      produit: produit,
      locvente: locvente,
      prix: prix,
      total: prix * quantite,
      quantite: quantite
    }
  end
end

boutique_count = 0
eshop_count = 0

# Skip QR sur le volume (sinon ~200 générations PNG rendent le seed très lent).
Commande.skip_callback(:create, :after, :generate_qr)

begin
  days.times do |days_ago|
    rng.rand(1..3).times do |slot|
      type_locvente = types_commande.sample(random: rng)
      articles = build_articles.call(type_locvente)
      montant = articles.sum { |a| a[:total] }

      Seeds::Helpers.upsert_demo_commande!(
        nom: format("Volume boutique J-%03d #%d", days_ago, slot + 1),
        client: clients.sample(random: rng),
        profile: profiles_boutique.sample(random: rng),
        days_ago: days_ago,
        type_locvente: type_locvente,
        statutarticles: statuts.sample(random: rng),
        articles: articles,
        paiements: [
          { typepaiement: "prix", montant: montant, moyen: moyens.sample(random: rng) }
        ]
      )
      boutique_count += 1
    end
  end

  # ~1 vente e-shop tous les 3 jours
  (0...days).step(3) do |days_ago|
    next if rng.rand < 0.15 && days_ago.positive?

    stripe_items = produits_eshop.sample(rng.rand(1..2), random: rng).map do |produit|
      unit = ((produit.prixvente || 80).to_i + rng.rand(-10..15)).clamp(15, 500) * 100
      { produit: produit, quantity: 1, unit_amount: unit }
    end
    amount_cents = stripe_items.sum { |i| i[:unit_amount] * i[:quantity] }

    Seeds::Helpers.upsert_demo_commande!(
      nom: format("Volume eshop J-%03d", days_ago),
      client: clients.sample(random: rng),
      profile: profile_eshop,
      days_ago: days_ago,
      type_locvente: "vente",
      eshop: true,
      articles: [],
      paiements: [],
      stripe: {
        stripe_payment_id: format("pi_seed_vol_%03d", days_ago),
        amount_cents: amount_cents,
        items: stripe_items
      }
    )
    eshop_count += 1
  end
ensure
  Commande.set_callback(:create, :after, :generate_qr)
end

Seeds::Helpers.log(
  "08",
  "#{boutique_count} commandes boutique + #{eshop_count} ventes e-shop sur #{days} jours"
)
