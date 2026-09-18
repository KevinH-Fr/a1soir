# frozen_string_literal: true

# Seed local : charge AnalysesDashboardDataset (spec/support) pour peupler le dashboard Analyses.
# Ignoré en production (db/seeds.rb return). Les dates sont ensuite recalées par 100_align_demo_dates.
Seeds::Helpers.log("99", "Jeu de données Analyses (période fixe mars 2026)")

require Rails.root.join("spec/support/analyses_dashboard_dataset")

if Commande.exists?(nom: "Boutique A")
  Seeds::Helpers.log("99", "Déjà chargé — ignoré")
else
  AnalysesDashboardDataset.seed!
end

Seeds::Helpers.log("99", "Données Analyses démo (dates recalées à J-3 par 100_align)")
