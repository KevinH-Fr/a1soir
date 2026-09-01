# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mensuration, type: :model do
  let(:invitation) do
    MensurationInvitation.create!(email: "jean@example.com", template: "homme", locale: "fr")
  end

  def build_mensuration(attrs = {})
    described_class.new({
      mensuration_invitation: invitation,
      template: invitation.template,
      locale: invitation.locale,
      prenom: "Jean",
      nom: "Dupont",
      measurements: { "hauteur" => "180" }
    }.merge(attrs))
  end

  describe ".fields_for" do
    it "expose des jeux de champs distincts pour femme et homme" do
      femme = described_class.fields_for("femme").map { |f| f["key"] }
      homme = described_class.fields_for("homme").map { |f| f["key"] }

      expect(femme).to include("taille_soutien_gorge")
      expect(homme).not_to include("taille_soutien_gorge")
      expect(homme).to include("tour_cou", "longueur_jambe_ext", "longueur_jambe_int")
      expect(femme).not_to include("tour_cou")
    end

    it "a un libellé i18n fr et en pour chaque champ" do
      keys = described_class.all_fields.values.flatten.map { |f| f["key"] }.uniq

      keys.each do |key|
        expect(I18n.t("mensurations.fields.#{key}.label", locale: :fr)).not_to include("translation missing")
        expect(I18n.t("mensurations.fields.#{key}.label", locale: :en)).not_to include("translation missing")
      end
    end
  end

  describe "#resolve_and_link_client!" do
    it "rattache au client existant (mail + nom) sans écraser sa fiche" do
      existing = Client.create!(
        nom: "Dupont", prenom: "Jean-Existant", mail: "jean@example.com",
        tel: "0600000000", ville: "Nice"
      )

      mensuration = build_mensuration(telephone: "0711111111", ville: "Cannes")
      mensuration.save!
      mensuration.resolve_and_link_client!

      expect(mensuration.reload.client).to eq(existing)
      expect(invitation.reload.client).to eq(existing)
      # La fiche client existante n'est pas modifiée.
      expect(existing.reload.tel).to eq("0600000000")
      expect(existing.ville).to eq("Nice")
      expect(existing.prenom).to eq("Jean-Existant")
    end

    it "crée un client si aucune correspondance mail + nom" do
      mensuration = build_mensuration(telephone: "0722222222", adresse: "1 rue Haute", cp: "06400", ville: "Cannes")
      mensuration.save!

      expect { mensuration.resolve_and_link_client! }.to change(Client, :count).by(1)

      client = mensuration.reload.client
      expect(client.mail).to eq("jean@example.com")
      expect(client.nom).to eq("Dupont")
      expect(client.tel).to eq("0722222222")
      expect(client.intitule).to eq("Monsieur")
    end

    it "ne matche pas sur le mail seul si le nom diffère" do
      Client.create!(nom: "Martin", mail: "jean@example.com")

      mensuration = build_mensuration
      mensuration.save!

      expect { mensuration.resolve_and_link_client! }.to change(Client, :count).by(1)
    end
  end

  describe "photo" do
    it "refuse un fichier non image" do
      mensuration = build_mensuration
      mensuration.photo_pied.attach(io: StringIO.new("plain"), filename: "notes.txt", content_type: "text/plain")

      expect(mensuration).not_to be_valid
    end
  end
end
