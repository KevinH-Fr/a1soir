class MeetingsController < ApplicationController

  before_action :authenticate_vendeur_or_admin!

  before_action :set_meeting, only: %i[ show edit update destroy ]

  def index
    @meetings = Meeting.all
    @commandes = Commande.all
    @clients = Client.all

    @meetings_periode = Meeting.where(
      datedebut: Time.now.beginning_of_month.beginning_of_week..
      Time.now.end_of_month.end_of_week)

    @calendar_type = params[:type] || 'month'

    respond_to do |format|
      format.html
      format.ics do
        cal = Icalendar::Calendar.new
        cal.x_wr_calname = 'A1soir_new_app2'

        @meetings.each do | meeting |

          cal.event do |e|


           e.last_modified = Time.now.utc

           e.dtstart     = meeting.start_time 
           e.dtend       = meeting.end_time 

          # e.dtstart     = Icalendar::Values::DateTime.new(meeting.start_time, tzid: "Europe/Paris")
          # e.dtend       = Icalendar::Values::DateTime.new(meeting.end_time, tzid: "Europe/Paris")
         
           e.summary     = meeting.full_name 
            e.description = meeting.full_details
            e.location    = meeting.lieu
            e.uid         = "UNIQUEv2#{meeting.id.to_s}"
            e.sequence    = Time.now.to_i
          end
        end
        
        cal.publish
        response.headers['Content-Type'] = 'text/calendar; charset=UTF-8'
        render plain: cal.to_ical
        
      end 
    end
  end

  # GET /meetings/1 or /meetings/1.json
  def show
  end

  # GET /meetings/new
  def new
    @meeting = Meeting.new
  end

  def edit
    @commande = @meeting.commande
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@meeting, 
          partial: "meetings/form", 
          locals: {meeting: @meeting})
      end
    end
  end

  # POST /meetings or /meetings.json
  def create
    @meeting = Meeting.new(meeting_params)

    respond_to do |format|
      if @meeting.save
        format.html { redirect_to meeting_url(@meeting), notice: "Meeting was successfully created." }
        format.json { render :show, status: :created, location: @meeting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meetings/1 or /meetings/1.json
  def update
    respond_to do |format|
      if @meeting.update(meeting_params)
        format.html { redirect_to meeting_url(@meeting), notice: "Meeting was successfully updated." }
        format.json { render :show, status: :ok, location: @meeting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meetings/1 or /meetings/1.json
  def destroy
    @meeting.destroy!

    respond_to do |format|
      format.html { redirect_to meetings_url, notice: "Meeting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meeting
      @meeting = Meeting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def meeting_params
      params.require(:meeting).permit(:nom, :datedebut, :datefin, :commande_id, :client_id, :lieu)
    end

end
