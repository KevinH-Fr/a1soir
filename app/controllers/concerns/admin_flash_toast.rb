# Toasts admin déclaratifs : étendre TOAST_REGISTRY pour d'autres domaines (commandes, clients, …).
# Utilisation : admin_push_domain_toast!(flash.now, :paiement_recu, :created)
# Passer des kwargs pour I18n.t (interpolation) ; futurs domaines peuvent étendre admin_toast_i18n_opts.
module AdminFlashToast
  extend ActiveSupport::Concern

  TOAST_REGISTRY = {
    defaults: {
      created: {
        variant: :success,
        icon: "check-circle-fill",
        message_key: "admin.toasts.defaults.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.defaults.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.defaults.destroyed",
      },
    },
    meeting: {
      created: {
        variant: :success,
        icon: "calendar-plus",
        message_key: "admin.toasts.meeting.created",
      },
      updated: {
        variant: :info,
        icon: "calendar-check",
        message_key: "admin.toasts.meeting.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.meeting.destroyed",
      },
      email_sent: {
        variant: :success,
        icon: "envelope-check-fill",
        message_key: "admin.toasts.meeting.email_sent",
      },
      reminder_enqueued: {
        variant: :info,
        icon: "clock-history",
        message_key: "admin.toasts.meeting.reminder_enqueued",
      },
    },
    rdv: {
      periode_created: {
        variant: :success,
        icon: "calendar-x-fill",
        message_key: "admin.toasts.rdv.periode_created",
      },
      periode_updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.rdv.periode_updated",
      },
      periode_destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.rdv.periode_destroyed",
      },
      type_created: {
        variant: :success,
        icon: "calendar-event-fill",
        message_key: "admin.toasts.rdv.type_created",
      },
      type_updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.rdv.type_updated",
      },
      type_destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.rdv.type_destroyed",
      },
      parametre_created: {
        variant: :success,
        icon: "gear-fill",
        message_key: "admin.toasts.rdv.parametre_created",
      },
      parametre_updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.rdv.parametre_updated",
      },
      parametre_destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.rdv.parametre_destroyed",
      },
    },
    doc_edition: {
      created: {
        variant: :success,
        icon: "file-earmark-plus-fill",
        message_key: "admin.toasts.doc_edition.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.doc_edition.updated",
      },
      email_sent: {
        variant: :success,
        icon: "envelope-check-fill",
        message_key: "admin.toasts.doc_edition.email_sent",
      },
    },
    sousarticle: {
      created: {
        variant: :success,
        icon: "plus-circle-fill",
        message_key: "admin.toasts.sousarticle.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.sousarticle.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.sousarticle.destroyed",
      },
    },
    commande: {
      created: {
        variant: :success,
        icon: "bag-check-fill",
        message_key: "admin.toasts.commande.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.commande.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.commande.destroyed",
      },
      statut_retire: {
        variant: :success,
        icon: "box-arrow-up",
        message_key: "admin.toasts.commande.statut_retire",
      },
      statut_non_retire: {
        variant: :info,
        icon: "box-arrow-in-down",
        message_key: "admin.toasts.commande.statut_non_retire",
      },
      rendu_avec_email: {
        variant: :success,
        icon: "envelope-check-fill",
        message_key: "admin.toasts.commande.rendu_avec_email",
      },
      rendu_sans_email: {
        variant: :info,
        icon: "check2-circle",
        message_key: "admin.toasts.commande.rendu_sans_email",
      },
      expedie_avec_email: {
        variant: :success,
        icon: "truck",
        message_key: "admin.toasts.commande.expedie_avec_email",
      },
      expedie_sans_email: {
        variant: :info,
        icon: "truck",
        message_key: "admin.toasts.commande.expedie_sans_email",
      },
    },
    selection_produit: {
      ensemble_introuvable: {
        variant: :warning,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.selection_produit.ensemble_introuvable",
      },
      selection_ensemble_introuvable: {
        variant: :warning,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.selection_produit.selection_ensemble_introuvable",
      },
      article_introuvable: {
        variant: :warning,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.selection_produit.article_introuvable",
      },
      locvente_manquant: {
        variant: :danger,
        icon: "exclamation-triangle-fill",
        message_key: "admin.toasts.selection_produit.locvente_manquant",
      },
      transform_ok: {
        variant: :success,
        icon: "shuffle",
        message_key: "admin.toasts.selection_produit.transform_ok",
      },
    },
    user: {
      role_updated: {
        variant: :success,
        icon: "person-check-fill",
        message_key: "admin.toasts.user.role_updated",
      },
    },
    etiquette: {
      selection_supprimee: {
        variant: :info,
        icon: "trash",
        message_key: "admin.toasts.etiquette.selection_supprimee",
      },
    },
    texte: {
      created: {
        variant: :success,
        icon: "megaphone-fill",
        message_key: "admin.toasts.texte.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.texte.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.texte.destroyed",
      },
      media_deleted: {
        variant: :success,
        icon: "image",
        message_key: "admin.toasts.texte.media_deleted",
      },
    },
    admin_parameter: {
      created: {
        variant: :success,
        icon: "sliders",
        message_key: "admin.toasts.admin_parameter.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.admin_parameter.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.admin_parameter.destroyed",
      },
    },
    message: {
      created: {
        variant: :success,
        icon: "chat-dots-fill",
        message_key: "admin.toasts.message.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.message.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.message.destroyed",
      },
    },
    demande_rdv: {
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.demande_rdv.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.demande_rdv.destroyed",
      },
    },
    demande_cabine: {
      created: {
        variant: :success,
        icon: "check-circle-fill",
        message_key: "admin.toasts.demande_cabine.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.demande_cabine.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.demande_cabine.destroyed",
      },
    },
    profile: {
      created: {
        variant: :success,
        icon: "person-plus-fill",
        message_key: "admin.toasts.profile.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.profile.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.profile.destroyed",
      },
    },
    type_produit: {
      created: {
        variant: :success,
        icon: "tags",
        message_key: "admin.toasts.type_produit.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.type_produit.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.type_produit.destroyed",
      },
    },
    categorie_produit: {
      created: {
        variant: :success,
        icon: "folder-plus",
        message_key: "admin.toasts.categorie_produit.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.categorie_produit.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.categorie_produit.destroyed",
      },
    },
    couleur: {
      created: {
        variant: :success,
        icon: "palette-fill",
        message_key: "admin.toasts.couleur.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.couleur.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.couleur.destroyed",
      },
    },
    taille: {
      created: {
        variant: :success,
        icon: "rulers",
        message_key: "admin.toasts.taille.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.taille.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.taille.destroyed",
      },
    },
    fournisseur: {
      created: {
        variant: :success,
        icon: "building-add",
        message_key: "admin.toasts.fournisseur.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.fournisseur.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.fournisseur.destroyed",
      },
    },
    ensemble: {
      created: {
        variant: :success,
        icon: "boxes",
        message_key: "admin.toasts.ensemble.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.ensemble.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.ensemble.destroyed",
      },
    },
    client: {
      created: {
        variant: :success,
        icon: "person-plus-fill",
        message_key: "admin.toasts.client.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.client.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.client.destroyed",
      },
    },
    article: {
      created: {
        variant: :success,
        icon: "journal-plus",
        message_key: "admin.toasts.article.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.article.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.article.destroyed",
      },
    },
    avoir_remb: {
      created: {
        variant: :success,
        icon: "receipt",
        message_key: "admin.toasts.avoir_remb.created",
      },
      updated: {
        variant: :info,
        icon: "pencil-square",
        message_key: "admin.toasts.avoir_remb.updated",
      },
      destroyed: {
        variant: :danger,
        icon: "trash",
        message_key: "admin.toasts.avoir_remb.destroyed",
      },
    },
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
