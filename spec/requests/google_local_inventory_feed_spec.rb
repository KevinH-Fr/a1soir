# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Google local inventory feed", type: :request do
  around do |example|
    old_merchant_host = ENV["MERCHANT_FEED_HOST"]
    old_local_limit = ENV["MERCHANT_LOCAL_FEED_LIMIT"]
    ENV["MERCHANT_FEED_HOST"] = "http://www.example.com"
    ENV.delete("MERCHANT_LOCAL_FEED_LIMIT")
    example.run
    if old_merchant_host
      ENV["MERCHANT_FEED_HOST"] = old_merchant_host
    else
      ENV.delete("MERCHANT_FEED_HOST")
    end
    if old_local_limit
      ENV["MERCHANT_LOCAL_FEED_LIMIT"] = old_local_limit
    else
      ENV.delete("MERCHANT_LOCAL_FEED_LIMIT")
    end
  end

  let!(:taille_m) { Taille.create!(nom: "m") }
  let!(:couleur_rouge) { Couleur.create!(nom: "rouge") }
  let!(:categorie_robes_courtes) { CategorieProduit.create!(nom: "robes courtes") }

  let!(:produit_in_feed) do
    p = Produit.create!(
      nom: "Robe flux local",
      description: "<p>Robe boutique</p>",
      prixvente: 695.0,
      poids: 500,
      stripe_price_id: "price_local_feed_001",
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 2,
      handle: "robe-flux-local",
      taille: taille_m,
      couleur: couleur_rouge
    )
    p.image1.attach(
      io: StringIO.new("fake-jpeg-bytes"),
      filename: "robe.jpg",
      content_type: "image/jpeg"
    )
    p.categorie_produits << categorie_robes_courtes
    p
  end

  let!(:produit_out_of_stock) do
    p = Produit.create!(
      nom: "Robe indisponible",
      prixvente: 99.0,
      stripe_price_id: "price_local_feed_002",
      eshop: true,
      actif: true,
      today_availability: false,
      quantite: 1,
      taille: taille_m,
      couleur: couleur_rouge
    )
    p.image1.attach(
      io: StringIO.new("fake-jpeg-bytes"),
      filename: "robe2.jpg",
      content_type: "image/jpeg"
    )
    p.categorie_produits << categorie_robes_courtes
    p
  end

  it "returns 200 with application/xml" do
    get "/google_local_inventory_feed.xml"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/xml")
  end

  it "outputs local inventory fields without full product attributes" do
    get "/google_local_inventory_feed.xml"
    body = response.body

    expect(body).to include('xmlns:g="http://base.google.com/ns/1.0"')
    expect(body).to include("<g:id>produit-#{produit_in_feed.id}</g:id>")
    expect(body).to include("<g:store_code>14941325208231197348</g:store_code>")
    expect(body).to include("<g:availability>in_stock</g:availability>")
    expect(body).to include("<g:quantity>2</g:quantity>")
    expect(body).to include("<g:price>695.00 EUR</g:price>")
    expect(body).to include("<g:pickup_method>buy</g:pickup_method>")
    expect(body).to include("<g:pickup_sla>next_day</g:pickup_sla>")

    expect(body).not_to include("<g:title>")
    expect(body).not_to include("<g:description>")
    expect(body).not_to include("<g:image_link>")
  end

  it "does not include products with today_availability false" do
    get "/google_local_inventory_feed.xml"
    expect(response.body).not_to include("produit-#{produit_out_of_stock.id}")
    expect(response.body).not_to include("Robe indisponible")
  end

  it "uses the same g:id as the main merchant feed" do
    get "/google_merchant_feed.xml"
    main_body = response.body

    get "/google_local_inventory_feed.xml"
    local_body = response.body

    id_tag = "<g:id>produit-#{produit_in_feed.id}</g:id>"
    expect(main_body).to include(id_tag)
    expect(local_body).to include(id_tag)
  end
end
