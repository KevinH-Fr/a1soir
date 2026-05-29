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

end
