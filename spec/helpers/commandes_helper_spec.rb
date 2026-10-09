# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommandesHelper, type: :helper do
  let(:client) do
    Client.create!(
      nom: "Durand",
      prenom: "Bob",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "helper-cmd-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Helper") }

  let(:eshop_commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop helper",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  let(:commande) { eshop_commande }

  describe "#frais_livraison_stripe_euros" do
    it "converts centimes to euros" do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_liv_#{SecureRandom.hex(6)}",
        amount: 6500,
        currency: "eur",
        status: "paid",
        frais_livraison_centimes: 950
      )

      expect(helper.frais_livraison_stripe_euros(eshop_commande.reload)).to eq(9.5)
    end

    it "returns 0 when there is no stripe payment" do
      expect(helper.frais_livraison_stripe_euros(eshop_commande)).to eq(0)
    end
  end

  describe "refunded shipping" do
    let!(:payment) do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_solde_#{SecureRandom.hex(6)}",
        amount: 11_000,
        currency: "eur",
        status: "paid",
        frais_livraison_centimes: 1_000,
        frais_livraison_rembourse_at: Time.current
      )
    end

    before do
      AvoirRemb.create!(
        commande: eshop_commande,
        type_avoir_remb: "remboursement",
        montant: 110,
        nature: "Stripe e-shop"
      )
    end

    it "keeps the historical shipping amount and drops it from the amount due" do
      expect(helper.frais_livraison_stripe_euros(eshop_commande.reload)).to eq(10)
      expect(helper.frais_livraison_dus_euros(eshop_commande)).to eq(0)
      expect(helper.du_prix(eshop_commande)).to eq(0)
      expect(helper.solde_prix(eshop_commande)).to eq(0)
    end

    it "keeps a cancelled article visible in history and out of the balance" do
      produit = Produit.create!(nom: "Helper robe annulee", prixvente: 100, quantite: 1, eshop: true)
      Article.create!(
        commande: eshop_commande,
        produit: produit,
        quantite: 1,
        locvente: "vente",
        prix: 100,
        total: 100,
        annule_at: Time.current
      )

      expect(eshop_commande.articles.count).to eq(1)
      expect(helper.du_prix(eshop_commande.reload)).to eq(0)
      expect(helper.solde_prix(eshop_commande)).to eq(0)
    end
  end

  describe "#pdf_afficher_paiements?" do
    it "is true for e-shop with paid stripe payment and no manual payments" do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_pdf_#{SecureRandom.hex(6)}",
        amount: 6000,
        currency: "eur",
        status: "paid"
      )

      expect(helper.pdf_afficher_paiements?(eshop_commande.reload)).to be(true)
    end

    it "is false for e-shop without paid stripe payment" do
      expect(helper.pdf_afficher_paiements?(eshop_commande)).to be(false)
    end
  end

  describe "#pdf_afficher_annulation_eshop?" do
    it "is true for facture on remboursee eshop commande" do
      payment = StripePayment.create!(
        commande: commande,
        stripe_payment_id: "pi_annul_#{SecureRandom.hex(6)}",
        amount: 6000,
        currency: "eur",
        status: "paid"
      )
      produit = Produit.create!(nom: "Helper annulation", prixvente: 60, quantite: 1, eshop: true)
      StripePaymentItem.create!(
        stripe_payment: payment,
        produit: produit,
        quantity: 1,
        unit_amount: 6000,
        refunded_at: Time.current
      )
      doc = DocEdition.new(commande: commande, doc_type: "facture")

      expect(helper.pdf_afficher_annulation_eshop?(commande.reload, doc)).to be(true)
    end
  end

  describe "#pdf_titre_document" do
    it "returns Facture for facture doc even when devis" do
      commande.update!(devis: true)
      doc = DocEdition.new(commande: commande, doc_type: "facture")

      expect(helper.pdf_titre_document(commande, doc)).to eq(I18n.t("document_types.facture"))
    end
  end

  describe "#pdf_afficher_livraison?" do
    it "is true when e-shop has a stripe payment record" do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_liv2_#{SecureRandom.hex(6)}",
        amount: 6000,
        currency: "eur",
        status: "paid"
      )

      expect(helper.pdf_afficher_livraison?(eshop_commande.reload)).to be(true)
    end
  end

  describe "totals with preloaded associations (PDF path)" do
    let!(:produit) { Produit.create!(nom: "Helper PDF produit", quantite: 5) }
    let!(:produit_sous) { Produit.create!(nom: "Helper PDF sous", quantite: 5) }
    let!(:article) do
      Article.create!(
        commande: eshop_commande,
        produit: produit,
        quantite: 2,
        locvente: "vente",
        prix: 50,
        total: 100,
        caution: 10
      )
    end
    let!(:sousarticle) do
      Sousarticle.create!(article: article, produit: produit_sous, prix: 25, caution: 5)
    end

    let(:commande_sql) { Commande.find(eshop_commande.id) }
    let(:commande_loaded) do
      Commande.includes(
        :paiement_recus,
        :avoir_rembs,
        articles: :sousarticles
      ).find(eshop_commande.id)
    end

    it "compte_articles matches SQL when articles are loaded" do
      expect(helper.compte_articles(commande_loaded)).to eq(helper.compte_articles(commande_sql))
      expect(helper.compte_articles(commande_loaded)).to eq(2)
    end

    it "du_prix matches SQL when articles are loaded" do
      expect(helper.du_prix(commande_loaded)).to eq(helper.du_prix(commande_sql))
      expect(helper.du_prix(commande_loaded)).to eq(125.0)
    end

    it "du_caution matches SQL when articles are loaded" do
      expect(helper.du_caution(commande_loaded)).to eq(helper.du_caution(commande_sql))
      expect(helper.du_caution(commande_loaded)).to eq(15)
    end

    it "recu_caution and avoir_deduit match SQL when collections are loaded" do
      PaiementRecu.create!(commande: eshop_commande, typepaiement: "caution", montant: 5, moyen: "CB")
      AvoirRemb.create!(commande: eshop_commande, type_avoir_remb: "avoir", montant: 20)

      sql = Commande.find(eshop_commande.id)
      loaded = Commande.includes(:paiement_recus, :avoir_rembs, articles: :sousarticles).find(eshop_commande.id)

      expect(helper.recu_caution(loaded)).to eq(helper.recu_caution(sql))
      expect(helper.avoir_deduit(loaded)).to eq(helper.avoir_deduit(sql))
      expect(helper.remb_deduit(loaded)).to eq(helper.remb_deduit(sql))
    end
  end
end
