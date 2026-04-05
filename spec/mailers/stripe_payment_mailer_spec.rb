# frozen_string_literal: true

require "rails_helper"

RSpec.describe StripePaymentMailer, type: :mailer do
  # Minimal shared fixtures ------------------------------------------------

  let!(:client) do
    Client.create!(
      prenom: "Alice",
      nom: "Dupont",
      mail: "alice@example.com",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first
    )
  end

  let!(:profile) { Profile.create!(prenom: "Vendeur", nom: "A1soir") }

  let!(:produit) do
    Produit.create!(
      nom: "Robe mailer test",
      prixvente: 80,
      stripe_price_id: "price_mailer_001",
      eshop: true,
      today_availability: true,
      quantite: 1
    )
  end

  let!(:commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop Stripe",
      montant: 80,
      devis: false,
      type_locvente: "vente",
      typeevent: Commande::EVENEMENTS_OPTIONS.first,
      eshop: true
    )
  end

  let!(:payment) do
    StripePayment.create!(
      stripe_payment_id: "pi_mailer_001",
      stripe_checkout_session_id: "cs_mailer_001",
      amount: 8000,
      currency: "eur",
      status: "paid",
      customer_email: "alice@example.com",
      commande: commande
    )
  end

  let!(:payment_item) do
    StripePaymentItem.create!(
      stripe_payment: payment,
      produit: produit,
      quantity: 1,
      unit_amount: 8000
    )
  end

  # -------------------------------------------------------------------------
  # confirmation
  # -------------------------------------------------------------------------

  describe "#confirmation" do
    subject(:mail) { described_class.confirmation(payment) }

    it "is sent to the customer email" do
      expect(mail.to).to include("alice@example.com")
    end

    it "has a subject" do
      expect(mail.subject).to be_present
    end

    it "renders in html and text formats" do
      expect(mail.html_part).to be_present
      expect(mail.text_part).to be_present
    end

    it "includes the product name in the body" do
      expect(mail.html_part.body.encoded).to include("Robe mailer test")
    end

    context "when customer_email is blank" do
      before { payment.update_column(:customer_email, nil) }

      it "returns a message with no recipients (guard return)" do
        # The mailer returns early when customer_email is blank —
        # ActionMailer still returns a mail object but it is not deliverable.
        result = described_class.confirmation(payment)
        expect(result.to).to be_nil.or be_blank
      end
    end
  end

  # -------------------------------------------------------------------------
  # notification_admin
  # -------------------------------------------------------------------------

  describe "#notification_admin" do
    context "when GMAIL_ACCOUNT is set" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("GMAIL_ACCOUNT").and_return("admin@a1soir.com")
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("GMAIL_ACCOUNT", anything).and_return("admin@a1soir.com")
      end

      subject(:mail) { described_class.notification_admin(payment) }

      it "is sent to the admin email" do
        expect(mail.to).to include("admin@a1soir.com")
      end

      it "has a subject" do
        expect(mail.subject).to be_present
      end

      it "renders in html and text formats" do
        expect(mail.html_part).to be_present
        expect(mail.text_part).to be_present
      end

      it "includes the product name" do
        expect(mail.html_part.body.encoded).to include("Robe mailer test")
      end
    end

    context "when GMAIL_ACCOUNT is blank" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("GMAIL_ACCOUNT").and_return(nil)
      end

      it "returns a message with no recipients (guard return)" do
        result = described_class.notification_admin(payment)
        expect(result.to).to be_nil.or be_blank
      end
    end
  end

  # -------------------------------------------------------------------------
  # expedition
  # -------------------------------------------------------------------------

  describe "#expedition" do
    before { commande.update_column(:numero_suivi, "2A12345678901") }

    subject(:mail) { described_class.expedition(commande) }

    it "is sent to the customer email" do
      expect(mail.to).to include("alice@example.com")
    end

    it "has a subject" do
      expect(mail.subject).to be_present
    end

    it "includes the tracking number in the body" do
      expect(mail.html_part.body.encoded).to include("2A12345678901")
    end

    it "includes a La Poste tracking URL" do
      expect(mail.html_part.body.encoded).to include("laposte.fr")
    end

    context "when customer_email is blank" do
      before do
        payment.update_column(:customer_email, nil)
      end

      it "returns a message with no recipients (guard return)" do
        result = described_class.expedition(commande)
        expect(result.to).to be_nil.or be_blank
      end
    end

    context "when numero_suivi is absent" do
      before { commande.update_column(:numero_suivi, nil) }

      it "does not include a tracking URL" do
        expect(mail.html_part.body.encoded).not_to include("laposte.fr")
      end
    end
  end
end
