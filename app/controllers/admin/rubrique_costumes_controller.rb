# frozen_string_literal: true

class Admin::RubriqueCostumesController < Admin::ApplicationController
  before_action :authenticate_admin!, only: %i[edit update destroy]
  before_action :set_rubrique_costume, only: %i[show edit update destroy]

  def index
    @count_rubrique_costumes = RubriqueCostume.count
    search_params = params.permit(:format, :page, q: [:nom_cont])
    @q = RubriqueCostume.ransack(search_params[:q])
    rubriques = @q.result(distinct: true).ordered
    @pagy, @rubrique_costumes = pagy_countless(rubriques, items: 20)
  end

  def show
    produits_scope = @rubrique_costume.produits
                                      .includes(Produit::CARD_INCLUDES)
                                      .order(updated_at: :desc)
    @pagy, @produits = pagy_countless(produits_scope, items: 8)
  end

  def new
    @rubrique_costume = RubriqueCostume.new(position: (RubriqueCostume.maximum(:position) || 0) + 1)
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          @rubrique_costume,
          partial: "admin/rubrique_costumes/form",
          locals: { rubrique_costume: @rubrique_costume, admin_form_row_embedded: true }
        )
      end
    end
  end

  def create
    @rubrique_costume = RubriqueCostume.new(rubrique_costume_params)

    respond_to do |format|
      if @rubrique_costume.save
        admin_push_domain_toast!(flash.now, :rubrique_costume, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              "new",
              partial: "admin/rubrique_costumes/form",
              locals: { rubrique_costume: RubriqueCostume.new, index_collapse: true }
            ),
            turbo_stream.prepend(
              "rubrique_costumes",
              partial: "admin/rubrique_costumes/rubrique_costume",
              locals: { rubrique_costume: @rubrique_costume }
            ),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :rubrique_costume, :created)
          redirect_to admin_rubrique_costume_url(@rubrique_costume)
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @rubrique_costume.update(rubrique_costume_params)
        admin_push_domain_toast!(flash.now, :rubrique_costume, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              @rubrique_costume,
              partial: "admin/rubrique_costumes/rubrique_costume",
              locals: { rubrique_costume: @rubrique_costume }
            ),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :rubrique_costume, :updated)
          redirect_to admin_rubrique_costume_url(@rubrique_costume)
        end
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            @rubrique_costume,
            partial: "admin/rubrique_costumes/form",
            locals: { rubrique_costume: @rubrique_costume, admin_form_row_embedded: true }
          )
        end
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless @rubrique_costume.hard_destroy_allowed?
      respond_with_destroy_blocked
      return
    end

    if @rubrique_costume.destroy
      respond_to do |format|
        admin_push_domain_toast!(flash.now, :rubrique_costume, :destroyed)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@rubrique_costume),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end
        format.html do
          admin_push_domain_toast!(flash, :rubrique_costume, :destroyed)
          redirect_to admin_rubrique_costumes_url
        end
      end
    else
      respond_with_destroy_blocked
    end
  rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
    respond_with_destroy_blocked
  end

  private

  def respond_with_destroy_blocked
    admin_push_domain_toast!(flash.now, :rubrique_costume, :destroy_blocked)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
      end
      format.html do
        admin_push_domain_toast!(flash, :rubrique_costume, :destroy_blocked)
        redirect_back fallback_location: admin_rubrique_costumes_url
      end
    end
  end

  def set_rubrique_costume
    @rubrique_costume = RubriqueCostume.find(params[:id])
  end

  def rubrique_costume_params
    params.require(:rubrique_costume).permit(:nom, :position)
  end
end
