# Configuration du sitemap
# Utilisez SitemapGenerator::Sitemap.default_host pour définir l'URL de base

# Déterminer le host selon l'environnement
if Rails.env.production?
  default_host = ENV.fetch('SITEMAP_HOST', 'https://shop.a1soir-2-2a03802389d6.herokuapp.com')
else
  default_host = ENV.fetch('SITEMAP_HOST', 'http://shop.lvh.me:3000')
end

SitemapGenerator::Sitemap.default_host = default_host

# Répertoire où les sitemaps seront générés (par défaut: public/)
SitemapGenerator::Sitemap.public_path = 'public/'

# Adapter pour utiliser le bon subdomain
SitemapGenerator::Sitemap.adapter = SitemapGenerator::FileAdapter.new

SitemapGenerator::Sitemap.create do
  # Pages statiques
  add '/home', changefreq: 'weekly', priority: 1.0
  add '/about', changefreq: 'monthly', priority: 0.8
  add '/cgv', changefreq: 'yearly', priority: 0.5
  add '/la_boutique', changefreq: 'weekly', priority: 0.9
  add '/nos_collections', changefreq: 'weekly', priority: 0.9
  add '/le_concept', changefreq: 'monthly', priority: 0.8
  add '/nos_autres_activites', changefreq: 'monthly', priority: 0.8
  add '/legal', changefreq: 'yearly', priority: 0.5
  add '/faq', changefreq: 'monthly', priority: 0.7
  add '/cabine_essayage', changefreq: 'weekly', priority: 0.8
  add '/contact', changefreq: 'monthly', priority: 0.7
  add '/categories', changefreq: 'weekly', priority: 0.9
  add '/rdv', changefreq: 'weekly', priority: 0.8
  add '/produits', changefreq: 'daily', priority: 1.0

  # Produits actifs
  Produit.actif.find_each do |produit|
    slug = produit.nom.parameterize
    add "/produit/#{slug}-#{produit.id}",
        changefreq: 'weekly',
        priority: 0.8,
        lastmod: produit.updated_at
  end

  # Catégories de produits (si vous avez des pages de catégories)
  CategorieProduit.find_each do |categorie|
    slug = categorie.nom.parameterize
    add "/produits/#{slug}-#{categorie.id}",
        changefreq: 'weekly',
        priority: 0.7,
        lastmod: categorie.updated_at
  end
end
