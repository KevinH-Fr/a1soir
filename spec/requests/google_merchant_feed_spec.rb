# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Google Merchant feed", type: :request do
  let(:feed_path) { Rails.root.join("public", GoogleMerchant::StaticFeed::FEED_FILENAME) }

  around do |example|
    old_merchant_host = ENV["MERCHANT_FEED_HOST"]
    ENV["MERCHANT_FEED_HOST"] = "http://www.example.com"
    example.run
    if old_merchant_host
      ENV["MERCHANT_FEED_HOST"] = old_merchant_host
    else
      ENV.delete("MERCHANT_FEED_HOST")
    end
  end

  let!(:taille_m) { Taille.create!(nom: "m") }
  let!(:couleur_rouge) { Couleur.create!(nom: "rouge") }
  let!(:categorie_robes_courtes) { CategorieProduit.create!(nom: "robes courtes") }

  let!(:produit_in_feed) do
    p = Produit.create!(
      nom: "Robe flux merchant",
      description: "<p>Superbe <strong>robe</strong></p>",
      prixvente: 129.5,
      poids: 500,
      stripe_price_id: "price_merchant_feed_001",
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 2,
      handle: "robe-flux-merchant",
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

  let!(:produit_no_image) do
    Produit.create!(
      nom: "Sans image",
      prixvente: 10,
      stripe_price_id: "price_merchant_feed_002",
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1
    )
  end

  after do
    FileUtils.rm_f(feed_path)
  end

  it "returns 200 with application/xml" do
    get "/google_merchant_feed.xml"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("application/xml")
  end

  it "outputs RSS 2.0 with Google namespace and the expected g: fields for a qualifying product" do
    get "/google_merchant_feed.xml"
    body = response.body

    expect(body).to include('xmlns:g="http://base.google.com/ns/1.0"')
    expect(body).to include("<rss version=\"2.0\"")
    expect(body).to include("<channel>")
    expect(body).to include("<item>")

    expect(body).to include("<g:id>produit-#{produit_in_feed.id}</g:id>")
    expect(body).to include("<g:title>Robe flux merchant</g:title>")
    expect(body).to include("<g:description>Superbe robe</g:description>")
    expect(body).to include("http://www.example.com/fr/produit/robe-flux-merchant-#{produit_in_feed.id}")
    expect(body).to match(%r{<g:image_link>https://res\.cloudinary\.com/dukne3lhz/image/upload/q_auto,f_auto,w_1200/[^<]+</g:image_link>})
    expect(body).to include("<g:availability>in_stock</g:availability>")
    expect(body).to include("<g:condition>new</g:condition>")
    expect(body).to include("<g:price>129.50 EUR</g:price>")
    expect(body).to include("<g:brand>Autour D'Un Soir</g:brand>")
    expect(body).to include("<g:shipping_weight>0.5 kg</g:shipping_weight>")
    expect(body).to include("<g:item_group_id>robe-flux-merchant</g:item_group_id>")
    expect(body).to include("<g:size>m</g:size>")
    expect(body).to include("<g:color>rouge</g:color>")
    expect(body).to include("<g:gender>female</g:gender>")
    expect(body).to include("<g:age_group>adult</g:age_group>")
  end

  it "does not include products without image1" do
    get "/google_merchant_feed.xml"
    expect(response.body).not_to include("Sans image")
  end
end
