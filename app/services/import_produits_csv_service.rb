class ImportProduitsCsvService
  require 'csv'
  require 'open-uri'

  def import_data_from_file(file_path, start_row, end_row)
    start_time = Time.now

    # Load existing categories and types in memory
    categories_hash = CategorieProduit.pluck(:nom, :id).to_h
    types_hash = TypeProduit.pluck(:nom, :id).to_h

    # Stream CSV rows instead of reading everything into memory
    CSV.foreach(file_path, headers: true).with_index(1) do |row, index|
      next if index < start_row
      break if index > end_row
      next if row['Published On'].to_s.strip.empty?  # Skip if 'Published On' is blank

      begin
        # Normalize category names
        category_names = row['Product Categories'].to_s.strip.split(';').map(&:strip).map(&:downcase)

        # Fetch or create categories in memory
        categorie_ids = category_names.map do |category_name|
          categories_hash[category_name] ||= CategorieProduit.find_or_create_by!(nom: category_name).id
        end

        # Define category mapping for type_produit
        category_to_type = {
          "robes courtes" => "robes",
          "robes longues" => "robes",
          "robes de mariée longues" => "robes",
          "robes de mariée courtes"  => "robes",
          "chaussures" => "chaussures"
        }

        # Determine type_produit_id efficiently
        type_name = category_names.map { |cat| category_to_type[cat] }.compact.first
        type_produit_id = type_name ? (types_hash[type_name] ||= TypeProduit.find_or_create_by!(nom: type_name).id) : nil

        # Create or find the size (taille)
        taille = Taille.find_or_create_by(nom: row['Option1 Value'].to_s.strip.downcase)

        # Prepare product attributes
        produit_attrs = {
          nom: row['Product Name'],
          prixvente: row['Variant Price'].gsub('€', '').to_f,
          description: row['Product Description'],
          quantite: row['Variant Inventory'].to_i,
          poids: row['Variant Weight'].to_f,
          reffrs: row['Variant Sku'],
          actif: true,
          eshop: true,
          taille_id: taille&.id,
          type_produit_id: type_produit_id
        }

        # Insert the product
        produit = Produit.create!(produit_attrs)

        # Associate the created categories with the product
        produit.categorie_produits = CategorieProduit.find(categorie_ids)

        # Attach images (Consider running in background jobs)
        attach_image(produit, row['Main Variant Image'], :image1)
        attach_images(produit, row['More Variant Images'])

        puts "________________Produit #{produit.nom} (#{index}) importé!________________"

      rescue StandardError => e
        puts "Erreur d'import pour #{row['Product Name']}: #{e.message}"
      end
    end

    puts "Import terminé en #{Time.now - start_time} secondes."
  end

  private

  def attach_image(produit, image_url, attachment_field)
    return unless image_url.present?

    begin
      downloaded_image = URI.open(image_url)
      produit.send(attachment_field).attach(
        io: downloaded_image,
        filename: File.basename(URI.parse(image_url).path),
        content_type: 'image/jpeg'
      )
    rescue OpenURI::HTTPError => e
      puts "Échec du téléchargement de l'image principale: #{e.message}"
    end
  end

  def attach_images(produit, images_string)
    return unless images_string.present?

    images_string.split(';').each do |image_url|
      begin
        downloaded_image = URI.open(image_url.strip)
        produit.images.attach(
          io: downloaded_image,
          filename: File.basename(URI.parse(image_url).path),
          content_type: 'image/jpeg'
        )
      rescue OpenURI::HTTPError => e
        puts "Échec du téléchargement d'une image de variante: #{e.message}"
      end
    end
  end
end
