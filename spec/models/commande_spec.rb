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

      it "is true when eshop, devis, and remboursement exist" do
        commande = Commande.create!(
          client: client,
          profile: profile,
          nom: "x",
          montant: 1,
          devis: true,
          eshop: true,
          type_locvente: "vente"
        )
        AvoirRemb.create!(
          commande: commande,
          type_avoir_remb: "remboursement",
          montant: 10
        )
        expect(commande.remboursee_eshop?).to be(true)
      end

      it "is false without remboursement" do
        commande = Commande.create!(
          client: client,
          profile: profile,
          nom: "x",
          montant: 1,
          devis: true,
          eshop: true,
          type_locvente: "vente"
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
          devis: false,
          eshop: false
        )
        expect(commande.a_completer?).to be(true)
        expect(Commande.a_completer).to include(commande)
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
