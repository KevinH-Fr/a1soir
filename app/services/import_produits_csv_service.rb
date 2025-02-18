require 'csv'
require 'open-uri'

class ImportProduitsCsvService
  # DEFAULT_PATH = Rails.root.join('app', 'data').freeze
  # DEFAULT_FILE_NAME = 'data_webflow.csv'.freeze

  # def initialize(path = DEFAULT_PATH, file_name = DEFAULT_FILE_NAME)
  #   @file_path = path.join(file_name)
  # end

  # The limit parameter controls how many items to process (default: nil for all items)
  def import_data_from_file(file_path, limit = nil)
    puts " _____ Call import data service ______"

    # Read the CSV data from the uploaded file
    csv_data = CSV.read(file_path, headers: true)

    # Apply limit if provided, else process all
    rows_to_process = limit.nil? ? csv_data : csv_data.first(limit)

    puts " _____ rows_to_process: #{rows_to_process.count} ______"

    return if rows_to_process.empty?

    # Process each row in the selected subset
    rows_to_process.each_with_index do |row, index|
      begin

        categorie_value = row['Product Categories']&.strip
        categorie = CategorieProduit.find_or_create_by(nom: categorie_value.downcase)

        taille_value = row['Option1 Value']&.strip
        taille = Taille.find_or_create_by(nom: taille_value.downcase)

        # Create the product
        produit = Produit.create!(
          nom: row['Product Name'],
          categorie_produit_id: categorie.id,
          prixvente: row['Variant Price'].gsub('€', ''),
          description: row['Product Description'],
          quantite: row['Variant Inventory'],
          actif: true,
          eshop: true,
          taille_id: taille&.id # Assign taille_id from found/created record
        )

        # Attach images from URLs
        attach_image(produit, row['Main Variant Image'], :image1)
        attach_images(produit, row['More Variant Images'])

        puts " _________________________________ Produit #{produit.nom} --- #{index + 1} out of #{rows_to_process.count} --- created successfully with images!_______________________________________________________"

      rescue StandardError => e
        puts "Error importing data for product #{row['Product Name']}: #{e.message}"
      end
    end
  end

  private

  # Attach the main image (single attachment)
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
      puts "Failed to download main image: #{e.message}"
    end
  end

  # Attach multiple variant images
  def attach_images(produit, images_string)
    return unless images_string.present?

    image_urls = images_string.split(';') # Assuming images are comma-separated

    image_urls.each do |image_url|
      begin
        downloaded_image = URI.open(image_url.strip)
        produit.images.attach(
          io: downloaded_image,
          filename: File.basename(URI.parse(image_url).path),
          content_type: 'image/jpeg'
        )
      rescue OpenURI::HTTPError => e
        puts "Failed to download variant image: #{e.message}"
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

