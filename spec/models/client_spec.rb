require 'rails_helper'

RSpec.describe 'Client' do           

    describe '#tel_or_mail_present' do
        context 'when neither tel nor mail is present' do
            it 'adds an error to the base' do
                client = Client.new # Create a new client without specifying tel or mail
                client.valid? # Trigger validations
        
                expect(client.errors[:base]).to include("Remplir le téléphone ou le mail")
            end
        end
    
        context 'when tel is present' do
            it 'does not add an error to the base' do
                client = Client.new(tel: '123456789') # Create a new client with tel
                client.valid? # Trigger validations
        
                expect(client.errors[:base]).to_not include("Remplir le téléphone ou le mail")
            end
        end
    
        context 'when mail is present' do
            it 'does not add an error to the base' do
                client = Client.new(mail: 'test@example.com') # Create a new user with mail
                client.valid? # Trigger validations
        
                expect(client.errors[:base]).to_not include("Remplir le téléphone ou le mail")
            end
        end
    end
    
end