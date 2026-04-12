# Toasts admin déclaratifs : étendre TOAST_REGISTRY pour d'autres domaines (commandes, clients, …).
# Utilisation : admin_push_domain_toast!(flash.now, :paiement_recu, :created)
# Passer des kwargs pour I18n.t (interpolation) ; futurs domaines peuvent étendre admin_toast_i18n_opts.
module AdminFlashToast
  extend ActiveSupport::Concern

  TOAST_REGISTRY = {
    paiement_recu: {
      created: {
        variant: :success,
        icon: "cash-stack",
        message_key: "admin.toasts.paiement_recu.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.paiement_recu.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.paiement_recu.destroyed",
      },
    },
    produit: {
      duplicate_exists: {
        variant: :warning,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.produit.duplicate_exists",
      },
      created: {
        variant: :success,
        icon: "bag-plus-fill",
        message_key: "admin.toasts.produit.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.produit.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.produit.destroyed",
      },
      destroy_blocked: {
        variant: :warning,
        icon: "link-45deg",
        message_key: "admin.toasts.produit.destroy_blocked",
      },
      image_deleted: {
        variant: :success,
        icon: "image",
        message_key: "admin.toasts.produit.image_deleted",
      },
      video_deleted: {
        variant: :success,
        icon: "camera-video-fill",
        message_key: "admin.toasts.produit.video_deleted",
      },
      duplicated: {
        variant: :success,
        icon: "files",
        message_key: "admin.toasts.produit.duplicated",
      },
      duplicate_no_base: {
        variant: :warning,
        icon: "question-circle-fill",
        message_key: "admin.toasts.produit.duplicate_no_base",
      },
      coup_de_coeur_added: {
        variant: :success,
        icon: "heart-fill",
        message_key: "admin.toasts.produit.coup_de_coeur_added",
      },
      coup_de_coeur_removed: {
        variant: :info,
        icon: "heart",
        message_key: "admin.toasts.produit.coup_de_coeur_removed",
      },
      save_error: {
        variant: :danger,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.produit.save_error",
      },
      coup_de_coeur_position_updated: {
        variant: :success,
        icon: "arrow-down-up",
        message_key: "admin.toasts.produit.coup_de_coeur_position_updated",
      },
      coup_de_coeur_not_found: {
        variant: :warning,
        icon: "exclamation-circle-fill",
        message_key: "admin.toasts.produit.coup_de_coeur_not_found",
      },
      promotion_price_invalid: {
        variant: :danger,
        icon: "currency-euro",
        message_key: "admin.toasts.produit.promotion_price_invalid",
      },
      promotion_requires_sale_price: {
        variant: :danger,
        icon: "currency-euro",
        message_key: "admin.toasts.produit.promotion_requires_sale_price",
      },
      promotion_applied: {
        variant: :success,
        icon: "tag-fill",
        message_key: "admin.toasts.produit.promotion_applied",
      },
      promotion_apply_error: {
        variant: :danger,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.produit.promotion_apply_error",
      },
      promotion_not_active: {
        variant: :warning,
        icon: "tag",
        message_key: "admin.toasts.produit.promotion_not_active",
      },
      promotion_removed: {
        variant: :success,
        icon: "tag",
        message_key: "admin.toasts.produit.promotion_removed",
      },
      promotion_remove_error: {
        variant: :danger,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.produit.promotion_remove_error",
      },
    },
  }.freeze

  private

  def admin_push_domain_toast!(flash_target, domain, event, **options)
    cfg = TOAST_REGISTRY.fetch(domain.to_sym).fetch(event.to_sym)
    append_admin_toast_payload!(
      flash_target,
      variant: cfg[:variant],
      icon: cfg[:icon],
      message: I18n.t(cfg[:message_key], **admin_toast_i18n_opts(domain, options)),
    )
  end

  # Options supplémentaires pour I18n.t (ex. interpolation). :record est réservé au domaine.
  def admin_toast_i18n_opts(domain, options)
    options.except(:record)
  end

  def append_admin_toast_payload!(flash_target, variant:, icon:, message:)
    flash_target[:admin_toasts] ||= []
    flash_target[:admin_toasts] = Array(flash_target[:admin_toasts])
    flash_target[:admin_toasts] << {
      "variant" => variant.to_s,
      "icon" => icon.to_s,
      "message" => message,
    }
  end
end
