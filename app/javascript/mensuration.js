import "@hotwired/turbo-rails"
import { installMensurationStepUrlSync } from "./mensuration/step_url"
import { application } from "./controllers/application"
import OtpSubmitController from "./controllers/otp_submit_controller"
import PhotoPreviewController from "./controllers/photo_preview_controller"
import FigureRulerController from "./controllers/figure_ruler_controller"
import ShareGateController from "./controllers/share_gate_controller"
import DevFillController from "./controllers/dev_fill_controller"
import MensurationStepUrlController from "./controllers/mensuration_step_url_controller"

application.register("otp-submit", OtpSubmitController)
application.register("photo-preview", PhotoPreviewController)
application.register("figure-ruler", FigureRulerController)
application.register("share-gate", ShareGateController)
application.register("dev-fill", DevFillController)
application.register("mensuration-step-url", MensurationStepUrlController)

installMensurationStepUrlSync()
