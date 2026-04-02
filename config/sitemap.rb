# Configuration du sitemap
# Utilisez SitemapGenerator::Sitemap.default_host pour définir l'URL de base

# Déterminer le host selon l'environnement
if Rails.env.production?
  # En production, on pointe toujours sur le domaine public (et pas sur le sous‑domaine admin)
  default_host = ENV.fetch('SITEMAP_HOST', 'https://a1soir.com')
else
  # En environnement non‑prod, on peut surcharger SITEMAP_HOST pour tester,
  # mais le host par défaut reste en local.
  default_host = ENV.fetch('SITEMAP_HOST', 'http://localhost:3000')
end

#SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.default_host = default_host

# Répertoire où les sitemaps seront générés (par défaut: public/)
SitemapGenerator::Sitemap.public_path = 'public/'

# Adapter pour utiliser le bon subdomain
SitemapGenerator::Sitemap.adapter = SitemapGenerator::FileAdapter.new

SitemapGenerator::Sitemap.create do
  # Pages statiques localisées
  [
    ['/home', 'weekly', 1.0],
    ['/la_boutique', 'weekly', 0.9],
    ['/nos_collections', 'weekly', 0.9],
    ['/le_concept', 'monthly', 0.8],
    ['/nos_autres_activites', 'monthly', 0.8],
    ['/cabine_essayage', 'weekly', 0.8],
    ['/contact', 'monthly', 0.7],
    ['/rdv', 'weekly', 0.8],
    ['/produits', 'daily', 0.6]
  ].each do |path, changefreq, priority|
    [:fr, :en].each do |locale|
      add "/#{locale}#{path}", changefreq: changefreq, priority: priority
    end
  end

  # Produits actifs
 # Produit.actif.find_each do |produit|
  #  slug = produit.nom.parameterize
  #  add "/produit/#{slug}-#{produit.id}",
  #      changefreq: 'weekly',
  #      priority: 0.4,
  #      lastmod: produit.updated_at
  #end

  # Catégories de produits (uniquement celles qui ne sont pas des services)
  #CategorieProduit.not_service.find_each do |categorie|
  #  slug = categorie.nom.parameterize
  #  add "/produits/#{slug}-#{categorie.id}",
  #      changefreq: 'weekly',
  #      priority: 0.7,
  #      lastmod: categorie.updated_at
  #end
  
end
