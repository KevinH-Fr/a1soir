module IndexModelHelper
  include ApplicationHelper

  def bandeau_entete_simple(title, icon)
    content_tag(:div, class: "card m-2 shadow-sm card-main-model-section") do
      concat(content_tag(:div, class: "card-header rounded bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "bi bi-xl brand-colored bi-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-6"))
        end)
      end)
    end
  end

  def bandeau_entete(title, icon, counter, champs_recherche, search_path, card_class: "card m-2 shadow-sm", show_new_record_button: true)
    content_tag(:div, class: [card_class, "card-main-model-section"].compact.join(" ").squish) do
      concat(content_tag(:div, class: "card-header rounded bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "bi bi-xl brand-colored bi-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-6"))
        end)

        if counter.present?
          concat(content_tag(:div, class: "mx-1 d-flex align-items-center flex-shrink-0") do
            concat(content_tag(:span, counter, class: "badge rounded-pill bg-primary fs-6"))
          end)
        end
      end)

      if champs_recherche.present?
        concat(content_tag(:div, class: "card-body p-1 light-beige-colored") do
          concat(content_tag(:div, class: "d-flex align-items-center") do
            concat(index_search_form(@q, search_path, champs_recherche))

            if show_new_record_button
              concat(content_tag(:button, class: "btn btn-sm btn-warning d-inline-flex align-items-center gap-1", type: "button",
                  data: { bs_toggle: "collapse", bs_target: "#collapseNew", aria_expanded: "false" },
                  aria: { controls: "collapseNew", label: "Nouveau" }) do
                concat(content_tag(:i, nil, class: "bi bi-plus-lg fa-xl", "aria-hidden": "true"))
                concat(content_tag(:span, "Nouveau", class: "d-none d-md-inline"))
              end)
            end
          end)
        end)
      end
    end
  end
  
  def index_search_form(q, chemin_recherche, champs_recherche)
    render partial: 'admin/shared/search_form', locals: {chemin_recherche: chemin_recherche, champs_recherche: champs_recherche }
  end

  # Ne pas mettre de padding sur l’élément .collapse (twbs/bootstrap#12093). Espacement : `admin_collapse_nouveau_inner_classes`.
  def bloc_nouveau(model_class, model_instance = nil, collapse_id = "collapseNew")
      # Gérer les cas spéciaux de noms de dossiers
      partial_path = case model_class.to_s
      when "PeriodeNonDisponible"
        "admin/periodes_non_disponibles/form"
      when "ParametreRdv"
        "admin/parametre_rdvs/form"
      else
        "admin/#{model_class.to_s.underscore.pluralize}/form"
      end

      model_sym = model_class.to_s.underscore.to_sym

      content_tag(:div, class: "collapse collapse-nouveau-admin", id: collapse_id) do
        concat(content_tag(:div, id: "new", class: admin_collapse_nouveau_inner_classes) do
          render partial: partial_path,
            locals: {
              model_sym => (model_instance || model_class.new),
              index_collapse: true
            }
        end)
      end
  end

  def links_record(model, turbo_delete: true, show: true, show_destroy: true, edit_params: nil)
    # Gérer le cas spécial de PeriodeNonDisponible où la route est periodes_non_disponibles (pluriel)
    edit_path = if model.class.name == "PeriodeNonDisponible"
      edit_admin_periodes_non_disponible_path(model)
    else
      edit_polymorphic_path([:admin, model])
    end
    
    show_path = if model.class.name == "PeriodeNonDisponible"
      admin_periodes_non_disponible_path(model)
    else
      polymorphic_path([:admin, model])
    end
    
    destroy_path = if model.class.name == "PeriodeNonDisponible"
      admin_periodes_non_disponible_path(model)
    else
      polymorphic_path([:admin, model])
    end
    
    # Masquer le bouton show pour ParametreRdv, TypeRdv, PeriodeNonDisponible et PaiementRecu
    hide_show = !show || ["ParametreRdv", "TypeRdv", "PeriodeNonDisponible", "PaiementRecu", "AvoirRemb"].include?(model.class.name)
    
    edit_button_opts = { method: :post, class: "btn btn-sm btn-secondary" }
    edit_button_opts[:params] = edit_params if edit_params.present?

    content_tag(:div, class: "d-flex justify-content-end gap-1 flex-nowrap") do
      unless hide_show
        concat(
          link_to(show_path, class: "btn btn-sm btn-primary d-inline-flex align-items-center", data: { turbo: false }) do
            content_tag(:i, "", class: "bi bi-arrow-up-right-square") +
              content_tag(:span, "Ouvrir", class: "d-none d-lg-inline ms-1")
          end
        )
      end

      concat(
        button_to(edit_path, edit_button_opts) do
          content_tag(:i, "", class: "bi bi-pencil-square") +
            content_tag(:span, "Modifier", class: "d-none d-lg-inline ms-1")
        end
      )

      if show_destroy
        concat(
          button_to(destroy_path, method: :delete, data: { turbo: turbo_delete },
            onclick: "return confirm('Êtes-vous certain de vouloir supprimer cet élément ?')",
            class: "btn btn-sm btn-danger d-inline-flex align-items-center") do
              content_tag(:i, "", class: "bi bi-trash") +
                content_tag(:span, "Supprimer", class: "d-none d-lg-inline ms-1")
          end
        )
      end
    end
  end
  

  def return_model_index_button(text, path)
    content_tag(:div, class: "m-1 d-flex align-items-center") do
      link_to path, class: "btn bg-dark text-light fw-bold d-flex align-items-center" do
          content_tag(:i, "", class: "bi bi-arrow-return-left") +
          content_tag(:span, text, class: "ms-2")
      end
    end
  end

end
