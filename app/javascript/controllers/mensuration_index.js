// Controllers chargés uniquement sur le flux mensurations public.

import { application } from "./application"

import OtpSubmitController from "./otp_submit_controller"
application.register("otp-submit", OtpSubmitController)

import PhotoPreviewController from "./photo_preview_controller"
application.register("photo-preview", PhotoPreviewController)

import FigureRulerController from "./figure_ruler_controller"
application.register("figure-ruler", FigureRulerController)

import ShareGateController from "./share_gate_controller"
application.register("share-gate", ShareGateController)

import DevFillController from "./dev_fill_controller"
application.register("dev-fill", DevFillController)

import MensurationStepUrlController from "./mensuration_step_url_controller"
application.register("mensuration-step-url", MensurationStepUrlController)
