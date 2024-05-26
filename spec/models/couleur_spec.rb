require 'rails_helper'

RSpec.describe 'Couleur' do           

    describe 'callbacks' do
        it 'downcases nom before validation' do
            couleur = Couleur.new(nom: 'TestName')
            couleur.valid? # Triggers validation callbacks
            expect(couleur.nom).to eq('testname')
        end
    
        it 'does not change nom if it is already downcased' do
            couleur = Couleur.new(nom: 'testname')
            couleur.valid? # Triggers validation callbacks
          expect(couleur.nom).to eq('testname')
        end
    
        it 'does not change nom if it is nil' do
            couleur = Couleur.new(nom: nil)
            couleur.valid? # Triggers validation callbacks
            expect(couleur.nom).to be_nil
        end
    end


end