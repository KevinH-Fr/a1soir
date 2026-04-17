module Chatbot
  class ToolDispatcher
    class UnknownToolError < StandardError; end

    def self.definitions
      [
        {
          type: "function",
          name: "search_products",
          description: "Search products by name and return availability.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "Product name or keyword to search"
              }
            },
            required: ["query"],
            additionalProperties: false
          }
        }
      ]
    end

    def self.call(name:, arguments:)
      normalized = arguments.is_a?(String) ? JSON.parse(arguments) : arguments
      normalized = {} unless normalized.is_a?(Hash)

      case name
      when "search_products"
        search_products(normalized)
      else
        raise UnknownToolError, "Unsupported tool: #{name}"
      end
    rescue JSON::ParserError
      { error: "Invalid tool arguments payload." }
    rescue StandardError => error
      {
        error: "Tool execution failed.",
        details: "#{error.class}: #{error.message}"
      }
    end

    def self.search_products(arguments)
      query = arguments["query"].to_s.strip
      return { error: "Missing query argument." } if query.blank?

      products = Produit
                 .where("LOWER(nom) LIKE ?", "%#{query.downcase}%")
                 .order(:nom)
                 .limit(5)
                 .map do |produit|
        {
          id: produit.id,
          nom: produit.nom,
          quantite: produit.quantite,
          today_availability: produit.today_availability
        }
      end

      {
        query: query,
        count: products.size,
        products: products
      }
    end
  end
end
