# spec/models/produit_spec.rb
require 'rails_helper'

RSpec.describe Produit do
    describe 'after_create callback' do
        it 'calls generate_qr after the model is created' do
            produit = Produit.new(nom: 'Test Product', reffrs: 'REF123')
            expect(produit).to receive(:generate_qr)
            produit.save
        end
    end

    describe '#generate_qr' do
        it 'calls the GenerateQr service with the model' do
            produit = Produit.new(nom: 'Test Product', reffrs: 'REF123')
            allow(GenerateQr).to receive(:call)
            produit.generate_qr
            expect(GenerateQr).to have_received(:call).with(produit)
        end
    end

end
