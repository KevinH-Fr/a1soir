class Admin::MeetingsController < ApplicationController

  #before_action :authenticate_vendeur_or_admin!

  before_action :set_meeting, only: %i[ show edit update destroy ]

  def index
    @count_meetings = Meeting.count

    search_params = params.permit(:format, :page, 
      q:[:nom_or_datedebut_or_datefin_or_lieu_cont])
    @q = Meeting.ransack(search_params[:q])
    meetings = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @meetings = pagy_countless(meetings, items: 2)

    
    @commandes = Commande.all
    @clients = Client.all

    @meetings_periode = Meeting.where(
      datedebut: Time.now.beginning_of_month.beginning_of_week..
      Time.now.end_of_month.end_of_week).includes(commande: :client)

    @calendar_type = params[:type] || 'month'

    respond_to do |format|
      format.html
      format.turbo_stream
      format.ics do

        puts " _____________ call ics cal __________"
        ics_file = MeetingIcsService.new(@meetings).generate
        puts " _____________ data: #{ics_file} __________"

        response.headers['Content-Type'] = 'text/calendar; charset=UTF-8'
        render plain: ics_file
      end 
    end
  end

  def download_ics
    @meetings = Meeting.all.includes(commande: :client)

    # Generate ICS content
    ics_file = MeetingIcsService.new(@meetings).generate

    # Set the response headers and render the ICS file
    send_data ics_file, filename: "meetings.ics", type: "text/calendar", disposition: "attachment"
  end

  # GET /meetings/1 or /meetings/1.json
  def show
  end

  # GET /meetings/new
  def new
    @meeting = Meeting.new

    @client = params[:client_id] 
    @commande = params[:commande_id] 

  end

  def edit
    @commande = @meeting.commande
    @client = @meeting.client
    

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

    @client = params[:client_id] 
    @commande = params[:commande_id] 

    respond_to do |format|
      if @meeting.save

        # Send reminder email after the meeting is successfully created
        MeetingMailer.reminder_email(@meeting).deliver_now

          flash.now[:success] =  "Meeting was created"
          
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update('new_meeting',
                partial: "meetings/form",
                  locals: { meeting: Meeting.new, commande_id: @meeting.commande_id, client_id: @meeting.client_id}),
                  
              turbo_stream.prepend('meetings',
                partial: "meetings/meeting",
                locals: { meeting: @meeting }),
                turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
              ]
          end
        
        format.html { redirect_to meeting_url(@meeting), notice: "Meeting was created" }
        format.json { render :show, status: :created, location: @meeting }
      else

        format.turbo_stream do
          render turbo_stream: 
            turbo_stream.update(@meeting,
              partial: "meetings/form", 
              locals: {meeting: @meeting, commande_id: @meeting.commande_id, client_id: @meeting.client_id}
            )
        end

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meetings/1 or /meetings/1.json
  def update
    respond_to do |format|
      if @meeting.update(meeting_params)

        flash.now[:success] = "Meeting was updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@meeting, partial: "meetings/meeting", locals: {meeting: @meeting}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to meeting_url(@meeting), notice: "Meeting was updated" }
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
      format.html { redirect_to meetings_url, notice: "Meeting was destroyed" }
      format.json { head :no_content }
    end
  end


  def send_reminder
    @meeting = Meeting.find(params[:meeting])

    MeetingMailer.reminder_email(@meeting).deliver_now

    respond_to do |format|
      flash.now[:success] = "Email was successfully created"

      format.html { redirect_to meeting_path(@meeting), notice: "email was successfully sended." }

    end
  end

  def send_reminder_job
    puts " ___________ call send reminder job _______________"
    @meeting = Meeting.find(params[:meeting])
    
    # Trigger the job asynchronously
    MeetingReminderJob.perform_now

    # Redirect with a notice
    redirect_to @meeting, notice: 'Reminder job has been enqueued.'
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
