import { application } from "./controllers/application"
import OtpSubmitController from "./controllers/otp_submit_controller"
import FormWizardController from "./controllers/form_wizard_controller"
import FormRevealController from "./controllers/form_reveal_controller"
import PhotoPreviewController from "./controllers/photo_preview_controller"

application.register("otp-submit", OtpSubmitController)
application.register("form-wizard", FormWizardController)
application.register("form-reveal", FormRevealController)
application.register("photo-preview", PhotoPreviewController)
