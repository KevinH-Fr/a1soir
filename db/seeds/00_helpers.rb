# frozen_string_literal: true

module Seeds
  module Helpers
    DEV_PASSWORD = ENV.fetch("SEED_DEV_PASSWORD", "password")

    module_function

    def log(step, message)
      puts "[seeds] #{step} — #{message}"
    end

    def seed_email(local)
      "#{local}@dev.a1soir.local"
    end

    # Les modèles Couleur, Taille, TypeProduit, CategorieProduit normalisent nom en minuscules.
    def find_nom!(model, nom)
      model.find_by!(nom: nom.to_s.downcase)
    end

    # Jours avant aujourd'hui (Hors période / Hors période seed > 30 → hors fenêtre par défaut).
    DEMO_COMMANDE_OFFSETS = {
      "Commande seed boutique mixte" => 2,
      "Commande seed non soldée" => 3,
      "Commande seed location Paul" => 9,
      "Commande seed vente Marie" => 6,
      "Commande seed eshop stripe" => 4,
      "Commande seed eshop robe" => 1,
      "Commande seed eshop cocktail" => 3,
      "Commande seed eshop costume" => 8,
      "Commande seed eshop duo" => 11,
      "Commande seed eshop semaine" => 16,
      "Commande seed eshop milieu" => 22,
      "Commande seed eshop préc." => 36,
      "Commande seed eshop préc. 2" => 40,
      "Commande seed ancienne" => 38,
      "Commande seed milieu mois" => 14,
      "Commande seed semaine" => 21,
      "Commande seed veille" => 1,
      "Commande seed veille bis" => 1,
      "Commande seed même jour mixte" => 2,
      "Commande seed période préc." => 35,
      "Commande seed période préc. 2" => 42,
      # CA du jour vs commandes : 1 commande J0 (50 €) + 2 du mois dernier payées aujourd'hui.
      "Commande seed CA jour 50 espèces" => 0,
      "Commande seed CA mois dernier 100 espèces" => 32,
      "Commande seed CA mois dernier 655 espèces" => 40,
      "Devis seed Marie" => 15,
      "Devis seed Paul" => 3,
      "Boutique A" => 5,
      "Boutique B" => 24,
      "Location jour 8" => 18,
      "E-shop C" => 7,
      "Hors période" => 50,
      "Devis A" => 12
    }.freeze

    # Heure déterministe 10h–18h dérivée du nom (pas Hash Ruby randomisé).
    # Plusieurs commandes le même days_ago → heures différentes pour juger le grain horaire.
    def demo_timestamp(days_ago, name: nil)
      base = days_ago.days.ago.in_time_zone
      hour = if name.present?
               10 + (name.to_s.bytes.sum % 9) # 10..18
             else
               11
             end
      base.change(hour: hour, min: 30, sec: 0)
    end

    def touch_commande_timestamps!(commande, at:)
      commande.update_columns(created_at: at, updated_at: at)
      commande.articles.update_all(created_at: at, updated_at: at)
      date = at.to_date
      commande.paiement_recus.find_each do |paiement|
        attrs = { created_at: at, updated_at: at }
        if paiement.custom_date.blank? || paiement.custom_date == paiement.created_at.in_time_zone.to_date
          attrs[:custom_date] = date
        end
        paiement.update_columns(attrs)
      end
      commande.stripe_payment&.update_columns(created_at: at, updated_at: at)
      if commande.stripe_payment
        StripePaymentItem.where(stripe_payment_id: commande.stripe_payment.id)
                         .update_all(created_at: at, updated_at: at)
      end
      AvoirRemb.where(commande_id: commande.id).update_all(
        created_at: at,
        updated_at: at,
        custom_date: at.to_date
      )
    end

    def wipe_seed_commande!(commande)
      return unless commande

      commande.paiement_recus.delete_all
      commande.articles.find_each { |article| article.sousarticles.delete_all }
      commande.articles.delete_all
      if (payment = commande.stripe_payment)
        payment.stripe_payment_items.delete_all
        payment.delete
      end
      commande.avoir_rembs.delete_all
      commande.delete
    end

    def align_demo_commandes_to_recent_period!
      DEMO_COMMANDE_OFFSETS.each do |nom, days_ago|
        commande = Commande.find_by(nom: nom)
        next unless commande

        touch_commande_timestamps!(commande, at: demo_timestamp(days_ago, name: nom))
      end
      log("align", "Commandes démo étalées sur les #{DEMO_COMMANDE_OFFSETS.values.max} derniers jours (heures 10h–18h)")
    end

    def upsert_demo_commande!(nom:, client:, profile:, days_ago:, devis: false, eshop: false, type_locvente: "vente", statutarticles: "retiré", articles: [], paiements: [], stripe: nil)
      at = demo_timestamp(days_ago, name: nom)
      commande = Commande.find_or_initialize_by(nom: nom)
      commande.assign_attributes(
        client: client,
        profile: profile,
        devis: devis,
        eshop: eshop,
        type_locvente: type_locvente,
        statutarticles: statutarticles,
        montant: articles.sum { |a| a[:total] || a[:prix] },
        created_at: at,
        updated_at: at
      )
      commande.save!

      commande.articles.destroy_all
      articles.each do |attrs|
        produit = attrs.fetch(:produit)
        locvente = attrs.fetch(:locvente)
        prix = attrs.fetch(:prix)
        total = attrs.fetch(:total, prix)
        quantite = attrs.fetch(:quantite, 1)

        commande.articles.create!(
          produit: produit,
          locvente: locvente,
          quantite: quantite,
          prix: prix,
          total: total,
          created_at: at,
          updated_at: at
        )
      end

      unless devis
        commande.paiement_recus.destroy_all
        paiements.each do |attrs|
          commande.paiement_recus.create!(
            typepaiement: attrs[:typepaiement],
            montant: attrs[:montant],
            moyen: attrs[:moyen],
            custom_date: attrs[:custom_date].presence || at.to_date,
            created_at: at,
            updated_at: at
          )
        end
      end

      if stripe && !devis
        payment = commande.stripe_payment || commande.build_stripe_payment
        payment.assign_attributes(
          stripe_payment_id: stripe[:stripe_payment_id] || payment.stripe_payment_id || "pi_seed_#{commande.id}",
          amount: stripe[:amount_cents],
          currency: "eur",
          status: "paid",
          created_at: at,
          updated_at: at
        )
        payment.save!
        payment.stripe_payment_items.destroy_all
        stripe.fetch(:items, []).each do |item|
          payment.stripe_payment_items.create!(
            produit: item[:produit],
            quantity: item[:quantity],
            unit_amount: item[:unit_amount],
            created_at: at,
            updated_at: at
          )
        end
      end

      touch_commande_timestamps!(commande, at: at)
      commande
    end

    def find_or_create_nom!(model, nom, **attrs)
      key = nom.to_s.downcase
      record = model.find_by(nom: key)
      if record
        record.update!(attrs) if attrs.present?
        record
      else
        model.create!(attrs.merge(nom: key))
      end
    end

    # PNG RGB uni (sans gem) pour pastilles de démo.
    def solid_png(width, height, red, green, blue)
      require "zlib"

      row = ([0] + ([red, green, blue] * width)).pack("C*")
      raw = row * height
      deflate = Zlib::Deflate.deflate(raw, Zlib::BEST_SPEED)
      ihdr = [width, height, 8, 2, 0, 0, 0].pack("N2C5")

      png_chunk = lambda do |type, data|
        [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
      end

      "\x89PNG\r\n\x1a\n".b <<
        png_chunk.call("IHDR", ihdr) <<
        png_chunk.call("IDAT", deflate) <<
        png_chunk.call("IEND", +"")
    end
  end
end
