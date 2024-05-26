# spec/models/taille_spec.rb
require 'rails_helper'

RSpec.describe Taille do
  describe 'validations' do
    it 'downcases nom before validation' do
      taille = Taille.new(nom: 'Small')
      taille.valid?
      expect(taille.nom).to eq('small')
    end

  end

end
