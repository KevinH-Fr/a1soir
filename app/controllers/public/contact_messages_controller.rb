module Public
  class ContactMessagesController < Public::ApplicationController
    include Pagy::Backend
    layout 'public'

    def create
      @contact_message = ContactMessage.new(contact_message_params)
      
      # Vérifier reCAPTCHA
      recaptcha_token = params['g-recaptcha-response']
      unless RecaptchaVerifier.verify(recaptcha_token, request.remote_ip)
        flash.now[:alert] = "Veuillez compléter le reCAPTCHA pour prouver que vous n'êtes pas un robot"
        respond_to do |format|
          format.html { render template: 'public/pages/contact', status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              :flash,
              partial: "public/shared/flash"
            )
          end
        end
        return
      end

      if @contact_message.save
        ContactMailer.contact_form(@contact_message).deliver_later
        redirect_to contact_path, notice: "Votre message a bien été envoyé. Nous vous répondrons dans les plus brefs délais."
      else
        respond_to do |format|
          format.html { render template: 'public/pages/contact', status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "contact_form",
              partial: "public/pages/contact_form",
              locals: { contact_message: @contact_message }
            )
          end
        end
      end
    end

    private

    def contact_message_params
      params.require(:contact_message).permit(:prenom, :nom, :email, :telephone, :sujet, :message)
    end
  end
end

