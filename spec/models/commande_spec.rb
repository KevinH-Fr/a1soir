require 'rails_helper'

RSpec.describe 'Commande' do
        
    describe '#date_retenue' do
        context 'when debutloc is present' do
          it 'returns the debutloc date' do
            commande = Commande.create(debutloc: Date.parse('2024-01-01'))
            expect(commande.date_retenue).to eq(Date.parse('2024-01-01'))
          end
        end
    
        context 'when debutloc is nil' do
          it 'returns today\'s date' do
            commande = Commande.create(debutloc: nil)
            expect(commande.date_retenue).to eq(Date.today)
          end
        end
    end

    describe '#remboursee_eshop?' do
      let(:client) do
        Client.create!(
          nom: "Test",
          prenom: "Remb",
          propart: "particulier",
          intitule: Client::INTITULE_OPTIONS.first,
          mail: "remb-model-#{SecureRandom.hex(4)}@test.com"
        )
      end

      let(:profile) { Profile.create!(prenom: "V", nom: "T") }

      it "is true when every stripe line is refunded" do
        commande = Commande.create!(
          client: client,
          profile: profile,
          nom: "x",
          montant: 1,
          devis: false,
          eshop: true,
          type_locvente: "vente"
        )
        payment = StripePayment.create!(
          commande: commande,
          stripe_payment_id: "pi_model_#{SecureRandom.hex(4)}",
          amount: 1000,
          currency: "eur",
          status: "paid"
        )
        produit = Produit.create!(nom: "Remb model", prixvente: 10, quantite: 1, eshop: true)
        StripePaymentItem.create!(
          stripe_payment: payment,
          produit: produit,
          quantity: 1,
          unit_amount: 1000,
          refunded_at: Time.current
        )
        expect(commande.remboursee_eshop?).to be(true)
      end

      it "is false while a stripe line remains" do
        commande = Commande.create!(
          client: client,
          profile: profile,
          nom: "x",
          montant: 1,
          devis: false,
          eshop: true,
          type_locvente: "vente"
        )
        payment = StripePayment.create!(
          commande: commande,
          stripe_payment_id: "pi_model_open_#{SecureRandom.hex(4)}",
          amount: 1000,
          currency: "eur",
          status: "paid"
        )
        produit = Produit.create!(nom: "Remb model open", prixvente: 10, quantite: 1, eshop: true)
        StripePaymentItem.create!(
          stripe_payment: payment,
          produit: produit,
          quantity: 1,
          unit_amount: 1000
        )
        expect(commande.remboursee_eshop?).to be(false)
      end
    end

    describe '#generate_qr' do
        it 'calls GenerateQr service with the commande instance' do
            commande = Commande.create(debutloc: Date.parse('2024-01-01'))
            expect(GenerateQr).to receive(:call).with(commande)
            commande.generate_qr
        end
    end

    describe "commande rapide" do
      it "marks a_completer when client or profile is technical" do
        commande = Commande.create!(
          client: Client.commande_rapide,
          profile: Profile.commande_rapide,
          type_locvente: "vente",
          devis: false,
          eshop: false
        )
        expect(commande.a_completer?).to be(true)
        expect(Commande.a_completer).to include(commande)
      end

      it "forces articles to vente while a_completer" do
        commande = Commande.create!(
          client: Client.commande_rapide,
          profile: Profile.commande_rapide,
          type_locvente: "vente",
          devis: false,
          eshop: false
        )
        produit = Produit.create!(nom: "Robe rapide", prixvente: 80, quantite: 1)
        article = Article.create!(
          commande: commande,
          produit: produit,
          locvente: "location",
          quantite: 1,
          prix: 80,
          total: 80
        )

        expect(article.locvente).to eq("vente")
        expect(commande.reload.type_locvente).to eq("vente")
      end

      it "detects missing location dates when a location article exists" do
        client = Client.create!(
          nom: "Loc",
          prenom: "Dates",
          propart: "particulier",
          intitule: Client::INTITULE_OPTIONS.first,
          mail: "dates-#{SecureRandom.hex(4)}@test.com"
        )
        profile = Profile.create!(prenom: "V", nom: "D")
        commande = Commande.create!(
          client: client,
          profile: profile,
          devis: false,
          type_locvente: "location"
        )
        produit = Produit.create!(nom: "Robe dates", prixlocation: 50, quantite: 1)
        Article.create!(
          commande: commande,
          produit: produit,
          locvente: "location",
          quantite: 1,
          prix: 50,
          total: 50
        )

        expect(commande.dates_location_manquantes?).to be(true)
        commande.update!(debutloc: Date.today, finloc: Date.today + 1)
        expect(commande.dates_location_manquantes?).to be(false)
      end

      it "detects missing event type or date" do
        commande = Commande.create!(
          client: Client.commande_rapide,
          profile: Profile.commande_rapide,
          type_locvente: "vente",
          devis: false,
          eshop: false
        )
        expect(commande.evenement_manquant?).to be(true)

        commande.update!(typeevent: "mariage")
        expect(commande.evenement_manquant?).to be(true)

        commande.update!(dateevent: Date.today)
        expect(commande.evenement_manquant?).to be(false)
      end
    end

end
