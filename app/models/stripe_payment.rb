class StripePayment < ApplicationRecord
  belongs_to :produit, optional: true # legacy — à supprimer avec migration future
  belongs_to :commande, optional: true
  has_many :stripe_payment_items, dependent: :destroy

  validates :stripe_payment_id, presence: true, uniqueness: true
  validates :stripe_checkout_session_id, uniqueness: true, allow_nil: true

  scope :paid, -> { where(status: "paid") }
  scope :a_expedier, -> { paid.joins(:commande).where(commandes: { expedie_le: nil }) }

  scope :filtredatedebut, ->(debut) { where("stripe_payments.created_at >= ?", debut.beginning_of_day) }
  scope :filtredatefin, ->(fin) { where("stripe_payments.created_at <= ?", fin.end_of_day) }

  # Somme des poids produits (grammes) × quantité — même logique que le checkout e-shop.
  def total_poids_grammes
    if stripe_payment_items.exists?
      return stripe_payment_items.joins(:produit).sum(
        Arel.sql("COALESCE(produits.poids, 0) * COALESCE(stripe_payment_items.quantity, 1)")
      )
    end

    return 0 unless commande_id.present?

    commande.articles.joins(:produit).sum(
      Arel.sql("COALESCE(produits.poids, 0) * COALESCE(articles.quantite, 1)")
    )
  end

  def colis_poids_calculable?
    stripe_payment_items.exists? || commande&.articles&.exists?
  end

  after_commit :update_produits_availability_if_paid, on: :update

  private

  def update_produits_availability_if_paid
    if saved_change_to_status? && status == "paid"
      stripe_payment_items.each do |item|
        item.produit&.update_today_availability
      end
    end
  end
end
