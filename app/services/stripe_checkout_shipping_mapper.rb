# frozen_string_literal: true

# Maps Stripe Checkout Session shipping / customer fields to StripePayment columns and Client attributes.
class StripeCheckoutShippingMapper
  class << self
    def stripe_payment_shipping_attrs(session)
      return phone_only_attrs(session) unless session.respond_to?(:shipping_details)

      details = session.shipping_details
      return phone_only_attrs(session) if details.blank?

      addr = details.respond_to?(:address) ? details.address : nil
      return phone_only_attrs(session) if addr.blank?

      line1 = addr.respond_to?(:line1) ? addr.line1.to_s.presence : nil
      line2 = addr.respond_to?(:line2) ? addr.line2.to_s.presence : nil
      city = addr.respond_to?(:city) ? addr.city.to_s.presence : nil
      postal = addr.respond_to?(:postal_code) ? addr.postal_code.to_s.presence : nil
      country = addr.respond_to?(:country) ? addr.country.to_s.presence : nil
      name = details.respond_to?(:name) ? details.name.to_s.presence : nil

      phone_only_attrs(session).merge(
        shipping_name: name,
        shipping_address_line1: line1,
        shipping_address_line2: line2,
        shipping_city: city,
        shipping_postal_code: postal,
        shipping_country: country
      ).compact
    end

    def address_fields_for_client(session)
      h = stripe_payment_shipping_attrs(session)
      line12 = [h[:shipping_address_line1], h[:shipping_address_line2]].compact.map(&:strip).reject(&:blank?)
      attrs = {}
      attrs[:adresse] = line12.join("\n").presence
      attrs[:cp] = h[:shipping_postal_code] if h[:shipping_postal_code].present?
      attrs[:ville] = h[:shipping_city] if h[:shipping_city].present?
      attrs[:pays] = h[:shipping_country] if h[:shipping_country].present?
      attrs[:tel] = h[:customer_phone] if h[:customer_phone].present?
      attrs
    end

    # Préfère la session ; si elle est vide (tests / ancien flux), utilise l’instantané StripePayment.
    def client_address_attrs(session, payment = nil)
      attrs = address_fields_for_client(session)
      return attrs if attrs.compact_blank.any?
      return {} if payment.blank?

      line12 = [payment.shipping_address_line1, payment.shipping_address_line2].compact.map(&:to_s).map(&:strip).reject(&:blank?)
      out = {}
      out[:adresse] = line12.join("\n").presence
      out[:cp] = payment.shipping_postal_code if payment.shipping_postal_code.present?
      out[:ville] = payment.shipping_city if payment.shipping_city.present?
      out[:pays] = payment.shipping_country if payment.shipping_country.present?
      out[:tel] = payment.customer_phone if payment.customer_phone.present?
      out
    end

    def shipping_recipient_name(session, payment = nil)
      payment&.shipping_name.presence || session_shipping_name(session)
    end

    def session_shipping_name(session)
      return unless session.respond_to?(:shipping_details)

      sd = session.shipping_details
      return if sd.blank?

      sd.name.to_s.presence if sd.respond_to?(:name)
    end

    def name_parts_from_shipping_name(shipping_name)
      full = shipping_name.to_s.strip
      return %w[Client E-shop] if full.blank?

      parts = full.split(/\s+/, 2)
      prenom = parts[0].presence || "Client"
      nom = parts[1].presence || "."
      [prenom, nom]
    end

    def commande_shipping_comment(payment)
      return if payment.blank?
      return unless payment.shipping_address_line1.present? || payment.shipping_city.present?

      line_street = [payment.shipping_address_line1, payment.shipping_address_line2].compact.map(&:strip).reject(&:blank?).join(", ")
      line_city = [payment.shipping_postal_code, payment.shipping_city].compact.map(&:strip).reject(&:blank?).join(" ")

      pieces = []
      pieces << payment.shipping_name if payment.shipping_name.present?
      pieces << line_street if line_street.present?
      pieces << line_city if line_city.present?
      pieces << payment.shipping_country if payment.shipping_country.present?
      pieces << "Tél. #{payment.customer_phone}" if payment.customer_phone.present?

      "Livraison: #{pieces.join(' — ')}"
    end

    def placeholder_eshop_client?(client)
      return false unless client.prenom.to_s.strip.casecmp?("client")

      nom_key = client.nom.to_s.strip.downcase.gsub(/[-\s]+/, " ").squeeze(" ")
      nom_key == "e shop"
    end

    private

    def phone_only_attrs(session)
      phone = extract_phone(session)
      return {} if phone.blank?

      { customer_phone: phone }
    end

    def extract_phone(session)
      return unless session.respond_to?(:customer_details)

      cd = session.customer_details
      return if cd.blank?

      if cd.respond_to?(:phone)
        cd.phone.to_s.presence
      elsif cd.respond_to?(:[]) && cd["phone"].present?
        cd["phone"].to_s.presence
      end
    end
  end
end
