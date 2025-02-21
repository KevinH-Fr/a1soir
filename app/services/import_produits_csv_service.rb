class ImportProduitsCsvService
  require 'csv'
  require 'open-uri'

  def import_data_from_file(file_path, start_row, end_row)
    csv_data = CSV.read(file_path, headers: true)
    
    # Validate row range
    start_row = [start_row, 1].max
    end_row = [end_row, csv_data.size].min
    rows_to_process = csv_data[(start_row - 1)..(end_row - 1)] || []

    return if rows_to_process.empty?

    rows_to_process.each_with_index do |row, index|
      begin
        # Split the categories by semicolon (or another separator if necessary)
        category_names = row['Product Categories'].to_s.strip.split(';')
    
        # Create categories and collect their IDs
        categorie_ids = category_names.map do |category_name|
          CategorieProduit.find_or_create_by(nom: category_name.strip.downcase).id
        end
    
        # Create or find the size (taille)
        taille = Taille.find_or_create_by(nom: row['Option1 Value'].to_s.strip.downcase)
    
        # Create the product (produit)
        produit = Produit.create!(
          nom: row['Product Name'],
          prixvente: row['Variant Price'].gsub('€', ''),
          description: row['Product Description'],
          quantite: row['Variant Inventory'],
          actif: true,
          eshop: true,
          taille_id: taille&.id
        )
    
        # Associate the created categories with the product
        produit.categorie_produits = CategorieProduit.find(categorie_ids)
    
        # Attach images
        attach_image(produit, row['Main Variant Image'], :image1)
        attach_images(produit, row['More Variant Images'])
    
        puts "_______________________ Produit #{produit.nom} (#{index + start_row}) importé! _____________________"
      rescue StandardError => e
        puts "Erreur d'import pour #{row['Product Name']}: #{e.message}"
      end
    end

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

# voir d'où viennet les couleurs dans le csv et comment les faire correspondre?
# possible de trouver ou créer la couleur à la volée comme les tailles
# voir si traitement sur ces champs : type_produit_id, :reffrs, :fournisseur_id, :dateachat, :prixachat, 


#   def import_all
#     CSV.foreach(@file_path, headers: true) do |row|
#       Produit.create!(
#         name: row['name'],
#         description: row['description'],
#         price: row['price'].to_f,
#         stock: row['stock'].to_i
#       )
#     end
#   end

