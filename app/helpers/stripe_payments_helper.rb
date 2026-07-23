module StripePaymentsHelper
  def stripe_payment_status_klass(payment)
    s = payment.status.to_s.downcase
    if %w[paid succeeded].include?(s)
      "text-bg-success-subtle text-success-emphasis border border-success-subtle"
    elsif %w[pending processing requires_payment_method requires_action requires_confirmation].include?(s)
      "text-bg-warning-subtle text-warning-emphasis border border-warning-subtle"
    elsif %w[failed canceled cancelled unpaid].include?(s)
      "text-bg-danger-subtle text-danger-emphasis border border-danger-subtle"
    else
      "text-bg-secondary-subtle text-secondary-emphasis border border-secondary-subtle"
    end
  end

  def stripe_payment_amount(payment)
    number_to_currency(payment.amount.to_f / 100, unit: "€", format: "%n %u", delimiter: " ")
  end

  def stripe_payment_expedition_badge(commande)
    if commande.nil?
      content_tag(:span, "—", class: "text-muted small")
    elsif commande.expedie_le.present?
      content_tag(:span,
                  class: "badge bg-success d-inline-flex align-items-center gap-1 fw-semibold shadow-sm",
                  title: "Expédié le #{l(commande.expedie_le, format: :short)}") do
        safe_join([tag.i(class: "bi bi-truck", aria: { hidden: true }), tag.span("Expédié")])
      end
    else
      content_tag(:span,
                  class: "badge border border-warning text-dark fw-semibold shadow-sm d-inline-flex align-items-center gap-1",
                  title: "Commande liée, pas encore marquée expédiée") do
        safe_join([tag.i(class: "bi bi-truck", aria: { hidden: true }), tag.span("À expédier")])
      end
    end
  end

  def stripe_payment_commande_link(commande)
    if commande
      link_to admin_commande_path(commande),
              class: "btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1",
              data: { turbo: false } do
        safe_join([tag.i(class: "bi bi-box-arrow-up-right", aria: { hidden: true }), commande.ref_commande])
      end
    else
      content_tag(:span, "—", class: "text-muted small")
    end
  end
end
