# frozen_string_literal: true

require "rails_helper"

RSpec.describe PagesHelper, type: :helper do
  # Une seule catégorie : l'id est dans le chemin (/produits/slug-id), sinon dans la query (id[]).
  def query_of(href)
    uri = URI.parse(href)
    query = Rack::Utils.parse_nested_query(uri.query.to_s)
    path_id = uri.path[%r{/produits/.+-(\d+)\z}, 1]
    path_id ? query.merge("id" => path_id) : query
  end

  def category_ids_in(href)
    Array(query_of(href)["id"]).map(&:to_i)
  end

  describe "#collection_card" do
    let!(:robes_longues) { CategorieProduit.create!(nom: "robes longues") }

    let(:html) do
      Nokogiri::HTML.fragment(
        helper.collection_card(
          title: "Tenues de soirée",
          items: [{ label: "Longues", category_name: "robes longues" }],
          url: "/fr/produits"
        )
      )
    end

    it "renders each tag as its own link, not nested inside the card link" do
      tag = html.at_css("a.cc-tag")

      expect(tag.text).to eq("Longues")
      expect(tag["href"]).to include("robes-longues-#{robes_longues.id}")
      expect(tag.ancestors("a")).to be_empty
    end

    it "links the card background and the CTA to the card URL" do
      expect(html.at_css("a.collection-card-stretched-link")["href"]).to eq("/fr/produits")
      expect(html.at_css("a.cc-cta")["href"]).to eq("/fr/produits")
      expect(html.at_css("a.cc-cta").ancestors("a")).to be_empty
    end
  end

  describe "#produits_filter_url" do
    it "adds the product type filter when the type exists" do
      type = TypeProduit.create!(nom: "combinaison pantalon")

      expect(query_of(helper.produits_filter_url(type_produit_name: "combinaison pantalon"))["type_produit"]).to eq(type.id.to_s)
    end

    it "omits the product type filter when the type does not exist" do
      expect(query_of(helper.produits_filter_url(type_produit_name: "inconnu"))).not_to have_key("type_produit")
    end
  end

  # Noms réels de production : une pastille qui vise un nom absent retombe sur tous les produits.
  describe "public/shared/section_categories" do
    let!(:categories) do
      ["robes de mariée courtes", "robes de mariée longues", "robes courtes", "robes longues",
       "ensembles pantalons", "costume", "enfants", "chaussures", "accessoires", "accessoires femmes"]
        .index_with { |nom| CategorieProduit.create!(nom: nom) }
    end
    let!(:combinaison_pantalon) { TypeProduit.create!(nom: "combinaison pantalon") }

    let(:html) { Nokogiri::HTML.fragment(helper.render(partial: "public/shared/section_categories")) }

    def tag_href(label)
      html.css("a.cc-tag").find { |node| node.text == label }["href"]
    end

    def cta_href_for_card_with_tag(label)
      card = html.css(".collection-card").find { |node| node.css("a.cc-tag").map(&:text).include?(label) }
      card.at_css("a.cc-cta")["href"]
    end

    it "gives every tag a filter instead of the unfiltered product list" do
      html.css("a.cc-tag").each do |tag|
        expect(query_of(tag["href"]).keys & %w[id type_produit q]).not_to be_empty,
          "#{tag.text} -> #{tag['href']}"
      end
    end

    it "sends Combinaisons to jumpsuits within ensembles pantalons" do
      query = query_of(tag_href("Combinaisons"))

      expect(query["id"].to_i).to eq(categories["ensembles pantalons"].id)
      expect(query["type_produit"].to_i).to eq(combinaison_pantalon.id)
    end

    it "sends Smokings to costumes matching smoking" do
      query = query_of(tag_href("Smokings"))

      expect(query["id"].to_i).to eq(categories["costume"].id)
      expect(query["q"].values).to eq(["smoking"])
    end

    it "covers costume and enfants in the suits discover-all link" do
      expect(category_ids_in(cta_href_for_card_with_tag("Smokings"))).to match_array(
        categories.values_at("costume", "enfants").map(&:id)
      )
    end
  end
end
