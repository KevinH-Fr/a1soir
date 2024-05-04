require 'rails_helper'

RSpec.describe 'Article' do           

    describe '#is_location' do

        it "saved article is location" do
            article = Article.create locvente: "location"
            expect(article.locvente).to eq "location"
        end
    
    end

    describe '#is_vente' do

        it "saved article is vente" do
            article = Article.create locvente: "vente"
            expect(article.locvente).to eq "vente"
        end
    
    end

end