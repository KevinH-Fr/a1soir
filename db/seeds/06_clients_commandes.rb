# frozen_string_literal: true

Seeds::Helpers.log("06", "Clients, commandes, paiements (volume Analyses)")

profile_marie = Profile.find_by!(prenom: "Marie", nom: "Dupont")
profile_paul = Profile.find_by!(prenom: "Paul", nom: "Martin")
profile_eshop = Profile.for_eshop_commandes

robe_cocktail = Produit.find_by!(nom: "Robe cocktail démo")
robe_soiree = Produit.find_by!(nom: "Robe soirée démo")
costume = Produit.find_by!(nom: "Costume smoking démo")

client_sophie = Client.find_or_create_by!(mail: "client@dev.a1soir.local") do |c|
  c.nom = "Bernard"
  c.prenom = "Sophie"
  c.propart = "particulier"
  c.intitule = Client::INTITULE_OPTIONS.first
  c.tel = "0600000001"
end

client_martin = Client.find_or_create_by!(mail: "martin@dev.a1soir.local") do |c|
  c.nom = "Martin"
  c.prenom = "Luc"
  c.propart = "particulier"
  c.intitule = Client::INTITULE_OPTIONS.first
  c.tel = "0600000002"
end

offsets = Seeds::Helpers::DEMO_COMMANDE_OFFSETS

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed boutique mixte",
  client: client_sophie,
  profile: profile_marie,
  days_ago: offsets["Commande seed boutique mixte"],
  type_locvente: "mixte",
  statutarticles: "retiré",
  articles: [
    { produit: robe_cocktail, locvente: "location", prix: 60, total: 60 },
    { produit: costume, locvente: "vente", prix: 90, total: 90 }
  ],
  # Lignes 150 €, encaissé 90 € → écart visible CA vs transactions.
  paiements: [
    { typepaiement: "prix", montant: 90, moyen: "carte bleue" }
  ]
)

# Lignes 200 € sans encaissement → transactions sans CA.
Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed non soldée",
  client: client_martin,
  profile: profile_paul,
  days_ago: offsets["Commande seed non soldée"],
  type_locvente: "vente",
  statutarticles: "non-retiré",
  articles: [
    { produit: costume, locvente: "vente", prix: 120, total: 120 },
    { produit: robe_cocktail, locvente: "vente", prix: 80, total: 80 }
  ],
  paiements: []
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed location Paul",
  client: client_martin,
  profile: profile_paul,
  days_ago: offsets["Commande seed location Paul"],
  type_locvente: "location",
  statutarticles: "non-retiré",
  articles: [
    { produit: robe_soiree, locvente: "location", prix: 80, total: 80, quantite: 1 },
    { produit: robe_soiree, locvente: "location", prix: 80, total: 80, quantite: 1 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 160, moyen: "carte bleue" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed vente Marie",
  client: client_sophie,
  profile: profile_marie,
  days_ago: offsets["Commande seed vente Marie"],
  type_locvente: "vente",
  statutarticles: "rendu",
  articles: [
    { produit: costume, locvente: "vente", prix: 150, total: 150 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 100, moyen: "chèque" },
    { typepaiement: "prix", montant: 50, moyen: "virement" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop stripe",
  client: client_martin,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop stripe"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_demo",
    amount_cents: 12_000,
    items: [
      { produit: robe_soiree, quantity: 1, unit_amount: 8000 },
      { produit: robe_cocktail, quantity: 1, unit_amount: 4000 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop robe",
  client: client_sophie,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop robe"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_robe",
    amount_cents: 8900,
    items: [
      { produit: robe_soiree, quantity: 1, unit_amount: 8900 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop cocktail",
  client: client_martin,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop cocktail"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_cocktail",
    amount_cents: 15_800,
    items: [
      { produit: robe_cocktail, quantity: 2, unit_amount: 7900 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop costume",
  client: client_sophie,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop costume"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_costume",
    amount_cents: 22_000,
    items: [
      { produit: costume, quantity: 1, unit_amount: 22_000 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop duo",
  client: client_martin,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop duo"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_duo",
    amount_cents: 17_500,
    items: [
      { produit: robe_soiree, quantity: 1, unit_amount: 9500 },
      { produit: robe_cocktail, quantity: 1, unit_amount: 8000 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop semaine",
  client: client_sophie,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop semaine"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_semaine",
    amount_cents: 6400,
    items: [
      { produit: robe_cocktail, quantity: 1, unit_amount: 6400 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop milieu",
  client: client_martin,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop milieu"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_milieu",
    amount_cents: 19_900,
    items: [
      { produit: costume, quantity: 1, unit_amount: 12_000 },
      { produit: robe_soiree, quantity: 1, unit_amount: 7900 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop préc.",
  client: client_sophie,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop préc."],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_prev",
    amount_cents: 11_000,
    items: [
      { produit: robe_soiree, quantity: 1, unit_amount: 11_000 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed eshop préc. 2",
  client: client_martin,
  profile: profile_eshop,
  days_ago: offsets["Commande seed eshop préc. 2"],
  type_locvente: "vente",
  eshop: true,
  articles: [],
  paiements: [],
  stripe: {
    stripe_payment_id: "pi_seed_eshop_prev2",
    amount_cents: 7800,
    items: [
      { produit: robe_cocktail, quantity: 1, unit_amount: 7800 }
    ]
  }
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed ancienne",
  client: client_sophie,
  profile: profile_paul,
  days_ago: offsets["Commande seed ancienne"],
  type_locvente: "vente",
  articles: [
    { produit: robe_cocktail, locvente: "vente", prix: 95, total: 95 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 95, moyen: "carte bleue" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Devis seed Marie",
  client: client_sophie,
  profile: profile_marie,
  days_ago: offsets["Devis seed Marie"],
  devis: true,
  type_locvente: "location",
  articles: [
    { produit: robe_soiree, locvente: "location", prix: 80, total: 80 }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Devis seed Paul",
  client: client_martin,
  profile: profile_paul,
  days_ago: offsets["Devis seed Paul"],
  devis: true,
  type_locvente: "location",
  articles: [
    { produit: costume, locvente: "location", prix: 90, total: 90 }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed veille",
  client: client_sophie,
  profile: profile_marie,
  days_ago: offsets["Commande seed veille"],
  type_locvente: "vente",
  statutarticles: "retiré",
  articles: [
    { produit: robe_cocktail, locvente: "vente", prix: 55, total: 55, quantite: 2 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 55, moyen: "carte bleue" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed veille bis",
  client: client_martin,
  profile: profile_paul,
  days_ago: offsets["Commande seed veille bis"],
  type_locvente: "location",
  statutarticles: "retiré",
  articles: [
    { produit: robe_soiree, locvente: "location", prix: 45, total: 45 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 45, moyen: "espèces" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed même jour mixte",
  client: client_sophie,
  profile: profile_paul,
  days_ago: offsets["Commande seed même jour mixte"],
  type_locvente: "vente",
  statutarticles: "retiré",
  articles: [
    { produit: costume, locvente: "vente", prix: 35, total: 35 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 35, moyen: "carte bleue" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed milieu mois",
  client: client_martin,
  profile: profile_paul,
  days_ago: offsets["Commande seed milieu mois"],
  type_locvente: "mixte",
  statutarticles: "non-retiré",
  articles: [
    { produit: robe_soiree, locvente: "location", prix: 70, total: 70 },
    { produit: costume, locvente: "vente", prix: 120, total: 120 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 100, moyen: "carte bleue" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed semaine",
  client: client_sophie,
  profile: profile_marie,
  days_ago: offsets["Commande seed semaine"],
  type_locvente: "location",
  statutarticles: "rendu",
  articles: [
    { produit: robe_soiree, locvente: "location", prix: 85, total: 85, quantite: 3 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 85, moyen: "virement" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed période préc.",
  client: client_martin,
  profile: profile_paul,
  days_ago: offsets["Commande seed période préc."],
  type_locvente: "vente",
  statutarticles: "retiré",
  articles: [
    { produit: costume, locvente: "vente", prix: 75, total: 75 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 75, moyen: "carte bleue" }
  ]
)

Seeds::Helpers.upsert_demo_commande!(
  nom: "Commande seed période préc. 2",
  client: client_sophie,
  profile: profile_marie,
  days_ago: offsets["Commande seed période préc. 2"],
  type_locvente: "location",
  statutarticles: "retiré",
  articles: [
    { produit: robe_cocktail, locvente: "location", prix: 65, total: 65 }
  ],
  paiements: [
    { typepaiement: "prix", montant: 65, moyen: "chèque" }
  ]
)
