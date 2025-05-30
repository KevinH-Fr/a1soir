class Admin::ProfilesController < Admin::ApplicationController

  before_action :authenticate_admin!

  before_action :set_profile, only: %i[ show edit update destroy ]

  def index
    search_params = params.permit(:format, :page, 
      q:[:nom_or_prenom_cont])
   @q = Profile.ransack(search_params[:q])
   profiles = @q.result(distinct: true).order(created_at: :desc)
   @pagy, @profiles = pagy_countless(profiles, items: 2)

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
          locals: {profile: @profile})
      end
    end
  end

  def create
    @profile = Profile.new(profile_params)

    respond_to do |format|
      if @profile.save

        flash.now[:success] = "profile was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "admin/profiles/form",
                                locals: { profile: Profile.new }),
  
            turbo_stream.prepend('profiles',
                                  partial: "admin/profiles/profile",
                                  locals: { profile: @profile }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to profile_url(@profile), notice:  "Création à jour réussie" }
        format.json { render :show, status: :created, location: @profile }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /profiles/1 or /profiles/1.json
  def update
    respond_to do |format|
      if @profile.update(profile_params)

        flash.now[:success] = "profile was successfully updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@profile, partial: "admin/profiles/profile", locals: {profile: @profile}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to profile_url(@profile), notice: "Mise à jour réussie" }
        format.json { render :show, status: :ok, location: @profile }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@profile, 
                    partial: 'admin/profiles/form', 
                    locals: { profile: @profile })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @profile.destroy!

    respond_to do |format|
      format.html { redirect_to profiles_url, notice:  "Suppression réussie" }
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
