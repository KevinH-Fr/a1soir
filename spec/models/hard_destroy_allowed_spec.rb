# frozen_string_literal: true

require "rails_helper"

RSpec.describe "hard_destroy_allowed?" do
  let(:client) do
    Client.create!(
      nom: "Dupont",
      prenom: "Jean",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "client-guard-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Test") }

  let(:commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Commande guard",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      typeevent: Commande::EVENEMENTS_OPTIONS.first
    )
  end

  describe Commande do
    it "returns true when no legacy paiements row exists" do
      expect(commande.hard_destroy_allowed?).to be(true)
    end

    it "returns false when a legacy paiements row exists" do
      skip "pas de table paiements" unless described_class.connection.data_source_exists?("paiements")

      commande
      described_class.connection.execute(
        described_class.sanitize_sql_array([
          "INSERT INTO paiements (typepaiement, montant, commande_id, moyen, commentaires, created_at, updated_at) " \
          "VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))",
          "prix",
          10,
          commande.id,
          "cb",
          nil
        ])
      )

      expect(commande.reload.hard_destroy_allowed?).to be(false)
    end
  end

  describe Profile do
    it "blocks the technical e-shop profile" do
      p = Profile.create!(prenom: Profile::ESHOP_PROFILE_PRENOM, nom: nil)
      expect(p.hard_destroy_allowed?).to be(false)
    end

    it "blocks when commandes exist" do
      commande
      expect(profile.reload.hard_destroy_allowed?).to be(false)
    end

    it "allows when no commandes and not e-shop profile" do
      p = Profile.create!(prenom: "Boutique", nom: "Vendeur")
      expect(p.hard_destroy_allowed?).to be(true)
    end
  end

  describe TypeProduit do
    it "blocks when a produit uses this type" do
      tp = TypeProduit.create!(nom: "type-guard-#{SecureRandom.hex(3)}")
      Produit.create!(nom: "Produit type guard", type_produit: tp)
      expect(tp.reload.hard_destroy_allowed?).to be(false)
    end

    it "blocks when an ensemble references this type in a slot" do
      tp = TypeProduit.create!(nom: "type-slot-#{SecureRandom.hex(3)}")
      produit_parent = Produit.create!(nom: "Parent ensemble")
      Ensemble.create!(produit: produit_parent, type_produit1: tp)
      expect(tp.reload.hard_destroy_allowed?).to be(false)
    end
  end

  describe CategorieProduit do
    it "blocks when linked via HABTM" do
      cat = CategorieProduit.create!(nom: "cat-guard-#{SecureRandom.hex(3)}")
      produit = Produit.create!(nom: "Produit cat guard")
      produit.categorie_produits << cat
      expect(cat.reload.hard_destroy_allowed?).to be(false)
    end

    it "blocks when a produit uses categorie_produit_id directly" do
      cat = CategorieProduit.create!(nom: "cat-direct-#{SecureRandom.hex(3)}")
      Produit.create!(nom: "Produit cat direct", categorie_produit: cat)
      expect(cat.reload.hard_destroy_allowed?).to be(false)
    end
  end

  describe Couleur do
    it "blocks when produits exist" do
      couleur = Couleur.create!(nom: "coul-guard-#{SecureRandom.hex(3)}")
      Produit.create!(nom: "Produit couleur", couleur: couleur)
      expect(couleur.reload.hard_destroy_allowed?).to be(false)
    end
  end

  describe Taille do
    it "blocks when produits exist" do
      taille = Taille.create!(nom: "tail-guard-#{SecureRandom.hex(3)}")
      Produit.create!(nom: "Produit taille", taille: taille)
      expect(taille.reload.hard_destroy_allowed?).to be(false)
    end
  end

  describe Ensemble do
    it "allows destroy by default" do
      produit_parent = Produit.create!(nom: "Ensemble parent")
      ensemble = Ensemble.create!(produit: produit_parent)
      expect(ensemble.hard_destroy_allowed?).to be(true)
    end
  end

  describe Client do
    let(:client_row) do
      Client.create!(
        nom: "Martin",
        prenom: "Claire",
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first,
        mail: "client-row-#{SecureRandom.hex(4)}@test.com"
      )
    end

    it "allows when no commandes or meetings" do
      expect(client_row.hard_destroy_allowed?).to be(true)
    end

    it "blocks when commandes exist" do
      Commande.create!(
        client: client_row,
        profile: profile,
        nom: "Cmd",
        montant: 1,
        devis: false,
        type_locvente: "vente",
        typeevent: Commande::EVENEMENTS_OPTIONS.first
      )
      expect(client_row.reload.hard_destroy_allowed?).to be(false)
    end

    it "blocks when meetings exist" do
      Meeting.create!(client: client_row, nom: "RDV", datedebut: 1.day.from_now)
      expect(client_row.reload.hard_destroy_allowed?).to be(false)
    end
  end

  describe Fournisseur do
    it "allows when no produits" do
      f = Fournisseur.create!(nom: "F-guard-#{SecureRandom.hex(3)}")
      expect(f.hard_destroy_allowed?).to be(true)
    end

    it "blocks when produits exist" do
      f = Fournisseur.create!(nom: "F-guard-#{SecureRandom.hex(3)}")
      Produit.create!(nom: "P-guard", fournisseur: f)
      expect(f.reload.hard_destroy_allowed?).to be(false)
    end
  end
end
