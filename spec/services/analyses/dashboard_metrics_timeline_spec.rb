# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::DashboardMetrics, "timeline grain" do
  around do |example|
    Time.use_zone("Europe/Paris") { example.run }
  end

  let(:client) do
    Client.create!(
      nom: "Grain",
      prenom: "Hour",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "grain-hour-#{SecureRandom.hex(4)}@test.com"
    )
  end
  let(:profile) { Profile.create!(prenom: "G", nom: "H") }
  let(:produit) { Produit.create!(nom: "Robe grain", prixvente: 50, quantite: 5) }

  let(:day) { Date.new(2026, 9, 19) }
  let(:controller) do
    Struct.new(:ivars) do
      def instance_variable_get(name)
        ivars[name]
      end

      def instance_variable_set(name, value)
        ivars[name] = value
      end
    end.new({})
  end

  def set_ivar(name, value)
    controller.instance_variable_set(:"@#{name}", value)
  end

  before do
    commande = Commande.create!(
      client: client,
      profile: profile,
      nom: "Cmd grain",
      montant: 150,
      devis: false,
      type_locvente: "vente",
      eshop: false
    )
    Article.create!(commande: commande, produit: produit, quantite: 1, prix: 100, total: 100, locvente: "vente")

    p10 = PaiementRecu.create!(
      commande: commande,
      typepaiement: "prix",
      moyen: "espèces",
      montant: 40,
      custom_date: day
    )
    p16 = PaiementRecu.create!(
      commande: commande,
      typepaiement: "prix",
      moyen: "carte bleue",
      montant: 60,
      custom_date: day
    )
    # Heures Paris 10h et 16h (stockées en UTC).
    p10.update_columns(created_at: Time.zone.local(2026, 9, 19, 10, 15), updated_at: Time.zone.local(2026, 9, 19, 10, 15))
    p16.update_columns(created_at: Time.zone.local(2026, 9, 19, 16, 0), updated_at: Time.zone.local(2026, 9, 19, 16, 0))

    # Encaissement backdaté : custom_date = jour, created_at = août.
    p_back = PaiementRecu.create!(
      commande: commande,
      typepaiement: "prix",
      moyen: "chèque",
      montant: 25,
      custom_date: day
    )
    p_back.update_columns(
      created_at: Time.zone.local(2026, 8, 10, 12, 0),
      updated_at: Time.zone.local(2026, 8, 10, 12, 0)
    )

    articles = Article.joins(:commande).where(commande_id: commande.id)
    set_ivar(:datedebut, day.beginning_of_day)
    set_ivar(:datefin, day.end_of_day)
    set_ivar(:commandesFiltres, Commande.where(id: commande.id))
    set_ivar(:articlesFiltres, articles)
    set_ivar(:sousArticlesFiltres, Sousarticle.joins(article: :commande).none)
    set_ivar(:paiementsFiltres, PaiementRecu.where(commande_id: commande.id))
    set_ivar(:remboursementsBoutiqueFiltres, AvoirRemb.none)
    set_ivar(:stripePaymentsPaidFiltres, StripePayment.none)
    set_ivar(:stripePaymentItemsFiltres, StripePaymentItem.none)
    set_ivar(:product_dimension_filtered, false)
    set_ivar(:analyses_ca_mode, :paiements)
    set_ivar(:total_stripe_eur, 0.to_d)
    set_ivar(:line_metrics, Analyses::LineMetrics.new(
      articles_scope: articles,
      stripe_items_scope: StripePaymentItem.none
    ))
  end

  it "buckets CA boutique by Paris hour for a single-day period" do
    travel_to Time.zone.local(2026, 9, 19, 18, 0, 0) do
      stripe_totals = Analyses::StripeTotals.new(
        datedebut: day,
        datefin: day,
        stripe_payments_scope: StripePayment.none
      )
      described_class.new(controller).assign_tab!(
        "ca",
        filter_params: {},
        stripe_totals: stripe_totals
      )

      expect(controller.instance_variable_get(:@timeline_grain)).to eq(:hour)
      boutique = controller.instance_variable_get(:@groupedByDateCaBoutique)
      expect(boutique["10h"]).to eq(40.to_d)
      expect(boutique["16h"]).to eq(60.to_d)
      # Backdate : heure de saisie (12h août) → bucket 12h, inclus car custom_date = jour.
      expect(boutique["12h"]).to eq(25.to_d)
      expect(boutique.keys).to all(match(/\A\d{1,2}h\z/))
    end
  end

  it "keeps day keys when the period spans multiple days" do
    set_ivar(:datedebut, (day - 1).beginning_of_day)
    set_ivar(:datefin, day.end_of_day)

    stripe_totals = Analyses::StripeTotals.new(
      datedebut: day - 1,
      datefin: day,
      stripe_payments_scope: StripePayment.none
    )
    described_class.new(controller).assign_tab!(
      "ca",
      filter_params: {},
      stripe_totals: stripe_totals
    )

    expect(controller.instance_variable_get(:@timeline_grain)).to eq(:day)
    boutique = controller.instance_variable_get(:@groupedByDateCaBoutique)
    expect(boutique["19/09/2026"]).to eq(125.to_d)
  end
end
