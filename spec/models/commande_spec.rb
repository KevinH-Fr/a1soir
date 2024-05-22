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

    describe '#generate_qr' do
        it 'calls GenerateQr service with the commande instance' do
            commande = Commande.create(debutloc: Date.parse('2024-01-01'))
            expect(GenerateQr).to receive(:call).with(commande)
            commande.generate_qr
        end
    end

end
