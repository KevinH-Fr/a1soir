# frozen_string_literal: true

namespace :google_places do
  desc "Rafraîchit la note et les avis Google de la boutique (1 appel Places API, à planifier 1 fois par jour)"
  task refresh: :environment do
    abort "[google_places] GOOGLE_PLACES_API_KEY ou GOOGLE_PLACE_ID manquant." unless GooglePlacesService.credentials_present?

    data = GooglePlacesService.refresh!
    abort "[google_places] Échec de l'appel Google ou de l'écriture du cache (détail dans les logs). Les derniers avis en cache sont conservés." if data.nil?

    puts "[google_places] Note #{data[:rating]} sur #{data[:user_rating_count]} avis, #{data[:reviews].size} avis en cache."
  end
end
