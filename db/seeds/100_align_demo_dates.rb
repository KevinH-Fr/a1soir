# frozen_string_literal: true

# Dernière étape seeds : recale les commandes démo dans les 30 derniers jours
# (période par défaut de la page Analyses). Development uniquement.
Seeds::Helpers.align_demo_commandes_to_recent_period!
