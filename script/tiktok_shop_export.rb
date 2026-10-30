# frozen_string_literal: true

# Export ponctuel des produits vers les modèles d'import en masse TikTok Seller Center (V5.0.2).
# Lecture seule : aucune écriture en base (bloc while_preventing_writes).
#
#   bin/rails runner script/tiktok_shop_export.rb
#   IDS=12,45,78 bin/rails runner script/tiktok_shop_export.rb
#   GROUPER=false bin/rails runner script/tiktok_shop_export.rb
#
# Base prod, depuis le poste local :
#   export DATABASE_URL="$(heroku config:get DATABASE_URL -a a1soir-2)"
#   bin/rails runner script/tiktok_shop_export.rb
#   unset DATABASE_URL
#
# Voir docs/memo-tiktok-shop.md.

require "rubyXL"
require "rubyXL/convenience_methods"

# Les modèles TikTok ont des dates d'entrées zip invalides : avertissement sans conséquence.
Zip.warn_invalid_date = false

EXCLURE_LOCATION = true
MOTS_EXCLUS = %w[mariee].freeze

# Identifiants créés dans Seller Center (fabricant et personne responsable, GPSR).
# Une variable d'environnement qui n'a pas la forme d'un identifiant (ex. "...") est ignorée.
MANUFACTURER_ID = ENV["TIKTOK_MANUFACTURER_ID"].to_s[/\A[[:alnum:]]+\z/] || "6ae3fa3b46e7999c9a4968c8"
RP_ID = ENV["TIKTOK_RP_ID"].to_s[/\A[[:alnum:]]+\z/] || "6ae3f98e76a11eeab816589a"
AVERTISSEMENT_SECURITE = "Non"
MARQUE = "Aucune marque"
POIDS_DEFAUT_G = 500
MAX_IMAGES = 9

# limite : nombre de produits TikTok (déclinaisons regroupées) par fichier ; prix : fourchette en EUR.
# Priorité des règles : type de produit, puis catégorie Rails, puis mots du nom (sans accents, minuscules).
MODELES = {
  "accessoires" => {
    fichier: "accessoires.xlsx",
    limite: 10,
    prix: 20..200,
    colis_cm: [25, 20, 5],
    regles: [
      { tiktok: "Accessoires de mode/Ceintures", mots: %w[ceinture], types: %w[ceinture] },
      { tiktok: "Accessoires de mode/Gants", mots: %w[gant gants] }
    ]
  },
  "robes" => {
    fichier: "robes.xlsx",
    limite: 10,
    prix: 50..200,
    colis_cm: [40, 30, 10],
    regles: [
      { tiktok: "Robes pour femmes/Robes de cérémonie/Robes de soirée", categories: %w[robe], types: %w[robe] }
    ]
  },
  "hommes" => {
    fichier: "hommes.xlsx",
    limite: 10,
    prix: 20..200,
    colis_cm: [35, 25, 5],
    regles: [
      { tiktok: "Hauts pour hommes/Chemises", categories: %w[chemise], types: %w[chemise] },
      { tiktok: "Vêtements hommes pour occasions spéciales/Costumes et accessoires", categories: %w[costume], types: %w[costume] }
    ]
  },
  "jupons" => {
    fichier: "jupons.xlsx",
    limite: 10,
    prix: 20..200,
    colis_cm: [30, 25, 5],
    regles: [
      { tiktok: "Sous-vêtements pour femmes/Vêtements de forme/Jupons gainants", mots: %w[jupon jupons] }
    ]
  }
}.freeze

TEMPLATES_DIR = Rails.root.join("lib/tiktok_shop/templates")
OUTPUT_DIR = Rails.root.join(ENV.fetch("OUTPUT_DIR", "tmp/tiktok_shop"))
PREMIERE_LIGNE_DONNEES = 6 # ligne 7 du fichier (index 0)

def normaliser(texte)
  I18n.transliterate(texte.to_s).downcase
end

def mots(texte)
  normaliser(texte).split(/[^a-z0-9]+/).reject(&:blank?)
end

def regle_pour(produit)
  mots_nom = mots(produit.nom)
  type = normaliser(produit.type_produit&.nom)
  categories = produit.categorie_produits.map { |c| normaliser(c.nom) }

  criteres = [
    ->(regle) { Array(regle[:types]).include?(type) },
    ->(regle) { (Array(regle[:categories]) & categories).any? },
    ->(regle) { (Array(regle[:mots]) & mots_nom).any? }
  ]
  criteres.each do |critere|
    MODELES.each do |modele, config|
      regle = config[:regles].find { |r| critere.call(r) }
      return [modele, regle[:tiktok]] if regle
    end
  end
  nil
end

def image_url(blob)
  "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/f_jpg,q_auto,c_limit,w_1600/#{blob.key}"
end

def images_pour(produit)
  blobs = [produit.image1.blob] + produit.images.map(&:blob)
  blobs.compact.uniq(&:key).first(MAX_IMAGES).map { |blob| image_url(blob) }
end

def description_pour(produit)
  html = produit.description.to_s
    .gsub(%r{<br\s*/?>}i, "\n")
    .gsub(%r{</(p|div|li|h\d)>}i, "\n")
  texte = ActionController::Base.helpers.strip_tags(html)
    .gsub(/&nbsp;/, " ")
    .lines.map(&:squish).reject(&:blank?).join("\n")
  texte = produit.nom.to_s if texte.blank?
  texte.truncate(5000)
end

DISPONIBLES = {}

def disponibles(produit)
  DISPONIBLES[produit.id] ||= produit.statut_disponibilite(Time.current, Time.current)[:disponibles].to_i
end

def motif_exclusion(produit, regle, impose:)
  return "pas d'image principale" unless produit.image1.attached?
  return "aucune catégorie TikTok correspondante (modèle à télécharger)" unless regle
  return "service" if produit.categorie_produits.any?(&:service)
  return "type ensemble (stock non suivi)" if produit.type_produit&.nom == "ensemble"
  return "prix de vente absent" unless produit.prixvente.to_d.positive?

  unless impose
    return "inactif" unless produit.actif?
    return "non diffusé sur l'e-shop" unless produit.eshop?
    prix = MODELES.fetch(regle.first)[:prix]
    return "prix hors fourchette #{prix} (#{produit.prixvente.to_f} EUR)" unless prix.cover?(produit.prixvente.to_d)
    return "proposé en location" if EXCLURE_LOCATION && produit.prixlocation.to_d.positive?

    mot = (MOTS_EXCLUS & mots(produit.nom)).first
    return "mot exclu : #{mot}" if mot
    return "indisponible aujourd'hui" unless produit.today_availability?
  end

  nil
end

def themes_variantes(groupe)
  return [] if groupe.size < 2

  themes = []
  themes << ["Couleur", ->(p) { p.couleur&.nom.presence || "Unique" }] if groupe.map(&:couleur_id).uniq.size > 1
  themes << ["Taille", ->(p) { p.taille&.nom.presence&.upcase || "Unique" }] if groupe.map(&:taille_id).uniq.size > 1
  themes
end

def colonnes(feuille)
  feuille[0].cells.each_with_index.each_with_object({}) do |(cellule, index), acc|
    acc[cellule.value.to_s] = index if cellule&.value.present?
  end
end

def categories_du_modele(classeur)
  feuille = classeur["Category"]
  return [] unless feuille

  feuille.sheet_data.rows.filter_map { |ligne| ligne&.cells&.first&.value }
end

# Les modèles téléchargés après la déclaration GPSR proposent une liste
# « Autour D'Un Soir (ID: ...) » : on reprend cette valeur exacte, sinon l'identifiant seul.
def valeur_gpsr(feuille, index_colonne, identifiant)
  return identifiant if index_colonne.nil? || identifiant.blank?

  cellule = RubyXL::Reference.ind2ref(PREMIERE_LIGNE_DONNEES, index_colonne)
  validation = Array(feuille.data_validations).find do |v|
    v.type.to_s == "list" && v.sqref.to_s.split.any? { |plage| plage.start_with?("#{cellule}:") || plage == cellule }
  end
  options = validation&.formula1&.expression.to_s.delete_prefix('"').delete_suffix('"').split(",")
  options.map(&:strip).find { |option| option.include?(identifiant) } || identifiant
end

def ecrire(feuille, ligne, index_colonne, valeur)
  return if index_colonne.nil? || valeur.nil?

  feuille.add_cell(ligne, index_colonne, valeur)
end

def lignes_pour(groupe, categorie, config, avertissements)
  principal = groupe.first
  themes = themes_variantes(groupe)
  images = images_pour(principal)
  longueur, largeur, hauteur = config[:colis_cm]

  vus = Set.new
  groupe.filter_map do |produit|
    valeurs = themes.map { |_nom, valeur| valeur.call(produit) }
    unless vus.add?(valeurs)
      avertissements << "#{produit.id} #{produit.nom} : déclinaison en double (#{valeurs.join(' / ')}), ignorée"
      next
    end

    ligne = {
      "category" => categorie,
      "brand" => MARQUE,
      "product_name" => principal.nom.to_s.truncate(255),
      "product_description" => description_pour(principal),
      "main_image" => images[0],
      "parcel_weight" => (produit.poids.to_i.positive? ? produit.poids.to_i : POIDS_DEFAUT_G),
      "parcel_length" => longueur,
      "parcel_width" => largeur,
      "parcel_height" => hauteur,
      "price" => produit.prixvente.to_d.round(2).to_f,
      "quantity" => disponibles(produit),
      "seller_sku" => GoogleMerchant::FeedFormatting.item_id(produit),
      "manufacturer_ids" => MANUFACTURER_ID.presence,
      "rp_ids" => RP_ID.presence,
      "product_property/102277" => AVERTISSEMENT_SECURITE
    }
    images.drop(1).each_with_index { |url, i| ligne["image_#{i + 2}"] = url }

    themes.each_with_index do |(nom, _), i|
      ligne["property_name_#{i + 1}"] = nom
      ligne["property_value_#{i + 1}"] = valeurs[i]
    end
    if themes.first&.first == "Couleur" && produit.image1.attached?
      ligne["property_1_image"] = image_url(produit.image1.blob)
    end

    ligne
  end
end

def exporter
  ids = ENV["IDS"].to_s.split(",").map(&:strip).reject(&:blank?).map(&:to_i)
  impose = ids.any?
  grouper = ENV.fetch("GROUPER", "true") != "false"

  base = Produit.includes(
    { image1_attachment: :blob }, { images_attachments: :blob },
    :taille, :couleur, :type_produit, :categorie_produits
  )
  candidats =
    if impose
      base.where(id: ids).to_a
    else
      prix_min = MODELES.values.map { |c| c[:prix].min }.min
      prix_max = MODELES.values.map { |c| c[:prix].max }.max
      base.actif.eshop_diffusion.where(prixvente: prix_min..prix_max)
        .order(coup_de_coeur: :desc, updated_at: :desc, id: :desc).to_a
    end

  exclus = []
  retenus = []
  candidats.each do |produit|
    regle = regle_pour(produit)
    motif = motif_exclusion(produit, regle, impose: impose)
    if motif
      exclus << [produit, motif]
    else
      retenus << [produit, *regle]
    end
  end

  tous_groupes = retenus.group_by { |produit, modele, categorie| [modele, categorie, grouper ? produit.handle.presence || "id-#{produit.id}" : "id-#{produit.id}"] }

  # Disponibilité exacte (plusieurs requêtes par produit) calculée seulement jusqu'à la limite.
  puts "Calcul des disponibilités (#{retenus.size} produits pré-retenus)..."
  groupes = {}
  par_modele = Hash.new(0)
  tous_groupes.each do |cle, membres|
    modele = cle.first
    next if !impose && par_modele[modele] >= MODELES.fetch(modele)[:limite]

    disponibles_membres = membres.select do |produit, _, _|
      next true if disponibles(produit) >= 1

      exclus << [produit, "indisponible aujourd'hui"]
      false
    end
    if disponibles_membres.any?
      groupes[cle] = disponibles_membres
      par_modele[modele] += 1
    end
    print "\r  #{par_modele.map { |m, n| "#{m} : #{n}" }.join(', ')}    "
  end
  puts
  puts

  FileUtils.mkdir_p(OUTPUT_DIR)
  avertissements = []
  avertissements << "TIKTOK_MANUFACTURER_ID vide : champ obligatoire" if MANUFACTURER_ID.blank?
  avertissements << "TIKTOK_RP_ID vide : champ obligatoire" if RP_ID.blank?
  fichiers = []

  groupes.group_by { |(modele, _, _), _| modele }.each do |modele, groupes_modele|
    config = MODELES.fetch(modele)
    classeur = RubyXL::Parser.parse(TEMPLATES_DIR.join(config[:fichier]).to_s)
    feuille = classeur["Template"]
    index = colonnes(feuille)
    categories_valides = categories_du_modele(classeur)
    gpsr = {
      "manufacturer_ids" => valeur_gpsr(feuille, index["manufacturer_ids"], MANUFACTURER_ID),
      "rp_ids" => valeur_gpsr(feuille, index["rp_ids"], RP_ID)
    }

    numero = PREMIERE_LIGNE_DONNEES

    groupes_modele.each do |(_, categorie, _), membres|
      unless categories_valides.include?(categorie)
        avertissements << "catégorie absente du modèle #{config[:fichier]} : #{categorie}"
        next
      end

      lignes_pour(membres.map(&:first), categorie, config, avertissements).each do |ligne|
        ligne.merge(gpsr).each do |cle, valeur|
          next if valeur.nil?

          if index.key?(cle)
            ecrire(feuille, numero, index[cle], valeur)
          else
            avertissements << "colonne #{cle} absente du modèle #{config[:fichier]}"
          end
        end
        numero += 1
      end
    end

    chemin = OUTPUT_DIR.join("#{modele}_#{Date.current.strftime('%Y%m%d')}.xlsx")
    classeur.write(chemin.to_s)
    fichiers << [chemin, numero - PREMIERE_LIGNE_DONNEES]
  end

  rapport(candidats, groupes, exclus, avertissements.uniq, fichiers)
end

def rapport(candidats, groupes, exclus, avertissements, fichiers)
  db = ActiveRecord::Base.connection_db_config
  puts "Base : #{db.adapter} #{db.database}"
  puts "Fabricant : #{MANUFACTURER_ID} — Personne responsable : #{RP_ID}"
  puts "Candidats examinés : #{candidats.size}"
  puts
  puts "Produits TikTok retenus : #{groupes.size}"
  groupes.each do |(modele, categorie, _), membres|
    produits = membres.map(&:first)
    puts "  [#{modele}] #{produits.first.nom} — #{categorie} — #{produits.size} déclinaison(s) : ids #{produits.map(&:id).join(', ')}"
  end
  puts
  puts "Exclus : #{exclus.size}"
  exclus.group_by(&:last).each do |motif, liste|
    puts "  #{motif} (#{liste.size}) : #{liste.first(15).map { |p, _| p.id }.join(', ')}#{liste.size > 15 ? ', ...' : ''}"
  end
  if avertissements.any?
    puts
    puts "Avertissements :"
    avertissements.each { |a| puts "  - #{a}" }
  end
  puts
  if fichiers.empty?
    puts "Aucun fichier écrit (aucun produit retenu)."
  else
    fichiers.each { |chemin, lignes| puts "Fichier écrit : #{chemin} (#{lignes} ligne(s))" }
  end
end

ActiveRecord::Base.while_preventing_writes { exporter }
