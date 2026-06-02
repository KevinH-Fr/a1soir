# frozen_string_literal: true

class StoreOpeningHours
  FALLBACK = [
    "Lundi: 10:00 - 17:00",
    "Mardi-Vendredi: 10:00 - 12:00 / 15:00 - 19:00",
    "Samedi: 10:00 - 17:00",
    "Dimanche: Ferme"
  ].freeze

  def self.lines(texte: Texte.last)
    rich_text = active_horaire(texte)
    parsed = plain_lines(rich_text)
    parsed.presence || FALLBACK
  rescue StandardError
    FALLBACK
  end

  def self.for_clothing_store_schema(texte: Texte.last)
    { "openingHours" => lines(texte: texte) }
  end

  def self.active_horaire(texte)
    return nil if texte.nil?

    texte.mode_periode_speciale? ? texte.horaire_periode_speciale : texte.horaire
  end

  def self.plain_lines(rich_text)
    rich_text&.to_plain_text&.split("\n")&.map(&:strip)&.reject(&:blank?)
  end

  private_class_method :active_horaire, :plain_lines
end
