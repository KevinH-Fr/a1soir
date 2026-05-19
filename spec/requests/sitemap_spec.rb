# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sitemap", type: :request do
  around do |example|
    old_host = ENV["SITEMAP_HOST"]
    ENV["SITEMAP_HOST"] = "http://www.example.com"
    example.run
    if old_host
      ENV["SITEMAP_HOST"] = old_host
    else
      ENV.delete("SITEMAP_HOST")
    end
  end

  let!(:categorie_robes) { CategorieProduit.create!(nom: "robes courtes") }

  let!(:produit_in_sitemap) do
    p = Produit.create!(
      nom: "Robe sitemap",
      prixvente: 99,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      handle: "robe-sitemap"
    )
    p.categorie_produits << categorie_robes
    p
  end

  def decompressed_body
    Zlib::GzipReader.new(StringIO.new(response.body)).read
  end

  it "returns 200 with gzip content type" do
    get "/sitemap.xml.gz"
    expect(response).to have_http_status(:ok)
    expect(response.content_type).to include("gzip")
  end

  it "sets Cache-Control for one week" do
    get "/sitemap.xml.gz"
    expect(response.headers["Cache-Control"]).to include("max-age=#{1.week.to_i}")
    expect(response.headers["Cache-Control"]).to include("public")
  end

  it "returns a valid urlset with static and catalogue URLs" do
    get "/sitemap.xml.gz"
    body = decompressed_body

    expect(body).to include('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    expect(body).to include("<loc>http://www.example.com/fr/home</loc>")
    expect(body).to include("<loc>http://www.example.com/en/produits</loc>")
    expect(body).to include(
      "<loc>http://www.example.com/fr/produits/robes-courtes-#{categorie_robes.id}</loc>"
    )
    expect(body).to include(
      "<loc>http://www.example.com/fr/produit/robe-sitemap-#{produit_in_sitemap.id}</loc>"
    )
  end

  it "excludes inactive or unavailable products" do
    Produit.create!(
      nom: "Hors sitemap inactif",
      prixvente: 10,
      eshop: true,
      actif: false,
      today_availability: true,
      quantite: 1
    )

    get "/sitemap.xml.gz"
    expect(decompressed_body).not_to include("Hors sitemap inactif")
  end
end
