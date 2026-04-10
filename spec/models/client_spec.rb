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

    describe '.create_from_demande' do
      FakeDemande = Struct.new(:prenom, :nom, :email, :telephone, keyword_init: true) do
        def respond_to?(method_name, include_private = false)
          method_name == :email || super
        end

        def to_client_attributes
          { prenom: prenom, nom: nom, tel: telephone, mail: email }
            .select { |_k, v| v.present? }
        end
      end

      let(:demande_lowercase) do
        FakeDemande.new(
          prenom: 'jean',
          nom: 'dupont',
          email: 'jean@example.com',
          telephone: '0612345678'
        )
      end

      before do
        Client.create!(
          nom: 'Dupont',
          prenom: 'Jean',
          mail: 'jean@example.com',
          tel: '0612345678',
          propart: 'particulier',
          intitule: Client::INTITULE_OPTIONS.first
        )
      end

      it 'reuses existing client when mail and nom match ignoring case' do
        client, created = Client.create_from_demande(demande_lowercase)
        expect(created).to be false
        expect(client.mail).to eq('jean@example.com')
        expect(client.nom).to eq('Dupont')
      end

      it 'reuses existing client via prenom+nom fallback when case differs' do
        other_mail = Client.create!(
          nom: 'Martin',
          prenom: 'Paul',
          mail: 'paul@example.com',
          tel: '0699999999',
          propart: 'particulier',
          intitule: Client::INTITULE_OPTIONS.first
        )

        demande = FakeDemande.new(
          prenom: 'paul',
          nom: 'martin',
          email: 'unique-fallback@example.com',
          telephone: '0688888888'
        )

        client, created = Client.create_from_demande(demande)
        expect(created).to be false
        expect(client.id).to eq(other_mail.id)
      end
    end
end