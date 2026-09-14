# frozen_string_literal: true

module Analyses
  # Décide quelles sections / graphiques afficher selon l'onglet et les filtres déjà « épinglés ».
  class DashboardVisibility
    VUES = %w[synthese ca catalogue equipe].freeze

    def self.normalize_vue(value)
      VUES.include?(value.to_s) ? value.to_s : "synthese"
    end

    def initialize(filter_params, ca_mode:, vue:)
      @filter_params = filter_params.to_h.symbolize_keys
      @ca_mode = ca_mode
      @vue = self.class.normalize_vue(vue)
    end

    attr_reader :vue

    def dimension_pinned?(dimension)
      case dimension.to_sym
      when :profile
        @filter_params[:filter_profile].present?
      when :type_produit
        @filter_params[:filter_type_produit].present?
      when :categorie
        @filter_params[:filter_categorie].present?
      when :couleur
        @filter_params[:filter_couleur].present?
      when :taille
        @filter_params[:filter_taille].present?
      when :locvente
        @filter_params[:filter_locvente].present?
      when :eshop
        @filter_params[:filter_eshop].present?
      else
        false
      end
    end

    def show?(widget)
      case widget.to_sym
      when :kpi
        VUES.include?(@vue)
      when :commandes_section
        @vue == "synthese"
      when :articles_locvente_split
        !dimension_pinned?(:locvente)
      when :articles_section
        @vue == "synthese"
      when :transactions_section
        @vue == "ca"
      when :ca_section
        @vue == "ca"
      when :ca_pie_payment_modes
        @ca_mode == :paiements
      when :catalog_section
        @vue == "catalogue"
      when :catalog_by_type
        !dimension_pinned?(:type_produit)
      when :catalog_by_categorie
        !dimension_pinned?(:categorie)
      when :profiles_section
        @vue == "equipe"
      when :profiles_comparison
        !dimension_pinned?(:profile)
      when :filter_profile_dropdown
        @vue != "equipe"
      else
        true
      end
    end

    def pinned_filter_messages
      messages = []
      if dimension_pinned?(:type_produit) && @vue == "catalogue"
        messages << { key: :filter_type_produit, label: "Type produit filtré — graphique par type masqué." }
      end
      if dimension_pinned?(:categorie) && @vue == "catalogue"
        messages << { key: :filter_categorie, label: "Catégorie filtrée — graphique par catégorie masqué." }
      end
      if dimension_pinned?(:locvente) && @vue == "synthese"
        messages << { key: :filter_locvente, label: "Location / vente filtré — répartition loc/vente masquée." }
      end
      if dimension_pinned?(:profile) && @vue == "equipe"
        messages << { key: :filter_profile, label: "Vendeur filtré — comparaison multi-vendeurs masquée." }
      end
      messages
    end
  end
end
