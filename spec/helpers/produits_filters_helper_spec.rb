# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProduitsFiltersHelper, type: :helper do
  describe "#filter_dropdown catalogue" do
    def catalogue_dropdown(filter_value = nil)
      parameters = {}
      parameters[:filter_catalogue] = filter_value if filter_value.present?
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(parameters))
      allow(helper).to receive(:url_for).and_return("/admin/produits")

      helper.filter_dropdown(
        label: "Catalogue",
        icon: "bi bi-shop",
        param_key: :filter_catalogue,
        current_params: {}
      )
    end

    it "shows the wedding catalogue when the filter is absent" do
      html = catalogue_dropdown

      expect(html).to match(/class="dropdown-item small active"[^>]*>Tenues de mariage et soirée/)
      expect(html).to include(">Tous<")
    end

    it "marks Tous when the filter asks for every catalogue" do
      html = catalogue_dropdown("tous")

      expect(html).to match(/class="dropdown-item small active"[^>]*>Tous/)
    end
  end

  describe "#filter_dropdown statut" do
    it "lists publication, eshop and availability choices" do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(filter_statut: %w[actif eshop]))
      allow(helper).to receive(:url_for).and_return("/admin/produits")

      html = helper.filter_dropdown(
        label: "Statut",
        icon: "bi bi-bookmark-check",
        param_key: :filter_statut,
        current_params: {},
        multiple: true,
        keep_label: false
      )

      expect(html).to include("actif, eshop")
      %w[actif archivé eshop pas\ eshop dispo pas\ dispo].each do |label|
        expect(html).to include(label)
      end
      expect(html).to include("is-selected")
    end
  end
end
