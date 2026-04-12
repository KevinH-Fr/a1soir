class Admin::ProfilesController < Admin::ApplicationController

  before_action :authenticate_admin!

  before_action :set_profile, only: %i[ show edit update destroy ]

  def index
    search_params = params.permit(:format, :page,
                                  q: [:nom_or_prenom_cont])
    @q = Profile.ransack(search_params[:q])
    profiles_scope = @q.result(distinct: true)
    @profiles_count = profiles_scope.count
    @pagy, @profiles = pagy_countless(profiles_scope.order(created_at: :desc), items: 2)
  end

  def show
  end

  def new
    @profile = Profile.new
  end

  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@profile,
          partial: "admin/profiles/form",
          locals: { profile: @profile, admin_form_row_embedded: true })
      end
    end
  end

  def create
    @profile = Profile.new(profile_params)

    respond_to do |format|
      if @profile.save

        admin_push_domain_toast!(flash.now, :profile, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "admin/profiles/form",
                                locals: { profile: Profile.new, index_collapse: true }),
  
            turbo_stream.prepend('profiles',
                                  partial: "admin/profiles/profile",
                                  locals: { profile: @profile }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :profile, :created)
          redirect_to profile_url(@profile)
        end
        format.json { render :show, status: :created, location: @profile }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("new",
            partial: "admin/profiles/form",
            locals: { profile: @profile, index_collapse: true })
        end

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profiles/1 or /profiles/1.json
  def update
    respond_to do |format|
      if @profile.update(profile_params)

        admin_push_domain_toast!(flash.now, :profile, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@profile, partial: "admin/profiles/profile", locals: {profile: @profile}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :profile, :updated)
          redirect_to profile_url(@profile)
        end
        format.json { render :show, status: :ok, location: @profile }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@profile,
                    partial: 'admin/profiles/form',
                    locals: { profile: @profile, admin_form_row_embedded: true })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @profile.destroy!

    respond_to do |format|
      format.html do
        admin_push_domain_toast!(flash, :profile, :destroyed)
        redirect_to profiles_url
      end
      format.json { head :no_content }
    end
  end

  private
    def set_profile
      @profile = Profile.find(params[:id])
    end

    def profile_params
      params.require(:profile).permit(:prenom, :nom, :profile_pic)
    end

end
