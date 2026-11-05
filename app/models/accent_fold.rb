# frozen_string_literal: true

# Pliage des accents pour la recherche. Une seule règle, dans +fold+.
# SQLite l'appelle via la fonction SQL accent_fold().
# PostgreSQL a translate() en natif : le SQL est bâti à partir de la même table.
class AccentFold
  LIGATURES = [%w[œ oe], %w[Œ oe], %w[æ ae], %w[Æ ae]].freeze

  # La valeur est déjà le caractère plié, minuscule comprise.
  GROUPS = {
    "a" => "àáâäãÀÁÂÄÃ",
    "e" => "éèêëÉÈÊË",
    "i" => "ïîìíÏÎÌÍ",
    "o" => "ôöòóõÔÖÒÓÕ",
    "u" => "ùûüúÙÛÜÚ",
    "y" => "ÿŸ",
    "c" => "çÇ",
    "n" => "ñÑ"
  }.freeze

  MAP = GROUPS.each_with_object({}) { |(ascii, chars), map|
    chars.each_char { |char| map[char] = ascii }
  }.freeze

  def self.fold(text)
    folded = utf8(text)
    LIGATURES.each { |from, to| folded = folded.gsub(from, to) }
    folded.each_char.map { |char| MAP[char] || char }.join.downcase
  end

  def self.words(text)
    fold(text).split(/[[:space:]]+/).reject(&:blank?)
  end

  def self.sql(column_sql)
    expr = "COALESCE(#{quote_column(column_sql)}, '')"
    return "accent_fold(#{expr})" if sqlite?

    LIGATURES.each do |from, to|
      expr = "replace(#{expr}, #{quote(from)}, #{quote(to)})"
    end
    "lower(translate(#{expr}, #{quote(MAP.keys.join)}, #{quote(MAP.values.join)}))"
  end

  def self.sqlite?
    ActiveRecord::Base.connection.adapter_name.match?(/sqlite/i)
  end

  def self.quote_column(column_sql)
    table, column = column_sql.split(".", 2)
    connection = ActiveRecord::Base.connection
    "#{connection.quote_table_name(table)}.#{connection.quote_column_name(column)}"
  end

  # SQLite remet les textes en binaire : « é » ferait deux octets.
  def self.utf8(value)
    text = value.to_s
    return text if text.encoding == Encoding::UTF_8

    text.dup.force_encoding(Encoding::UTF_8)
  end

  def self.quote(value)
    ActiveRecord::Base.connection.quote(value)
  end

  private_class_method :sqlite?, :quote_column, :utf8, :quote
end
