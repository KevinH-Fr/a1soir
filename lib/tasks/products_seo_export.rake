# frozen_string_literal: true

require "csv"

namespace :products do
  desc "Export products for SEO rename workflow"
  task seo_export: :environment do
    path = Rails.root.join("tmp", "produits_seo_export.csv")

    headers = %w[
      id
      handle
      old_nom
      couleur
      taille
      description
      stripe_product_id
      stripe_price_id
      actif
      eshop
      today_availability
      prixvente
    ]

    rows = []

    Produit
      .includes(:couleur, :taille)
      .where(actif: true, eshop: true, today_availability: true)
      .find_each do |p|
        rows << [
          p.id,
          p.handle,
          p.nom,
          p.couleur&.nom,
          p.taille&.nom,
          p.description,
          p.stripe_product_id,
          p.stripe_price_id,
          p.actif,
          p.eshop,
          p.today_availability,
          p.prixvente
        ]
      end

    csv_content = CSV.generate(write_headers: true, headers: headers) do |csv|
      rows.each { |row| csv << row }
    end

    File.write(path, csv_content)

    if Rails.env.production?
      puts csv_content
    else
      puts
      puts "Export termine :"
      puts path
      puts "Lignes exportees : #{rows.size}"
      puts
    end
  end
end