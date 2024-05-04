require 'rails_helper'

RSpec.describe 'User' do           

    describe '#set_default_role' do

        it "save user if no role" do
            user = User.create role: nil
            expect(user.role).to eq "user"
        end


        it "keeps admin if admin is setted" do
            user = User.create role: 'admin'
            expect(user.role).to eq "admin"
        end

        it "keeps vendeur if vendeur is setted" do
            user = User.create role: 'vendeur'
            expect(user.role).to eq "vendeur"
        end
    end

end