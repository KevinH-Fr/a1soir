class DocEditionsController < ApplicationController
  before_action :set_doc_edition, only: %i[ show edit update destroy ]

  # GET /doc_editions or /doc_editions.json
  def index
    @doc_editions = DocEdition.all
  end

  # GET /doc_editions/1 or /doc_editions/1.json
  def show
  end

  # GET /doc_editions/new
  def new
    @doc_edition = DocEdition.new doc_edition_params
  end

  # GET /doc_editions/1/edit
  def edit
  end

  # POST /doc_editions or /doc_editions.json
  def create
    @doc_edition = DocEdition.new(doc_edition_params)

    respond_to do |format|
      if @doc_edition.save
        format.html { redirect_to doc_edition_url(@doc_edition), notice: "Doc edition was successfully created." }
        format.json { render :show, status: :created, location: @doc_edition }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @doc_edition.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /doc_editions/1 or /doc_editions/1.json
  def update
    respond_to do |format|
      if @doc_edition.update(doc_edition_params)
        format.html { redirect_to doc_edition_url(@doc_edition), notice: "Doc edition was successfully updated." }
        format.json { render :show, status: :ok, location: @doc_edition }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @doc_edition.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /doc_editions/1 or /doc_editions/1.json
  def destroy
    @doc_edition.destroy!

    respond_to do |format|
      format.html { redirect_to doc_editions_url, notice: "Doc edition was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_doc_edition
      @doc_edition = DocEdition.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def doc_edition_params
      params.fetch(:doc_edition, {}).permit(:commande_id, :doc_type, :edition_type, :commentaires)
    end
end
