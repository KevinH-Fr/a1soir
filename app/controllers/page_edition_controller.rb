# app/controllers/page_edition_controller.rb

class PageEditionController < ApplicationController
  before_action :set_current_step, only: [:new, :create]

  def new
    @page_edition = PageEdition.new
  end

  def create
    # Handle form submission and save data for the current step
    case @current_step
    when 1
      @page_edition.attributes = page_edition_params.merge(step: 2)
    when 2
      @page_edition.attributes = page_edition_params.merge(step: 3)
    when 3
      # Handle final step submission
    end

    if @page_edition.save
      redirect_to next_step_path
    else
      render :new
    end
  end

  private

  def set_current_step
    @current_step = params[:step].to_i || 1
  end

  def next_step_path
    case @current_step
    when 1 then new_page_edition_path(step: 2)
    when 2 then new_page_edition_path(step: 3)
    when 3 then page_editions_path # Redirect to the final step or wherever you need
    end
  end

  def page_edition_params
    params.require(:page_edition).permit(:doc_type, :comment, :edition_type)
  end
end
