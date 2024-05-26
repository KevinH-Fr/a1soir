# spec/models/type_produit_spec.rb
require 'rails_helper'

RSpec.describe TypeProduit do
  describe 'validations' do
    it 'downcases nom before validation' do
      type_produit = TypeProduit.new(nom: 'Type1')
      type_produit.valid?
      expect(type_produit.nom).to eq('type1')
    end

    it 'validates presence and uniqueness of nom' do
      TypeProduit.create(nom: 'Type1')
      type_produit = TypeProduit.new(nom: 'Type1')
      type_produit.valid?
      expect(type_produit.errors[:nom]).to include('est déjà utilisé(e)')
    end
  end

end
