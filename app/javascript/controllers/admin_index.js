// Controllers chargés uniquement sur les pages admin
// Contient tous les controllers y compris ceux spécifiques à l'administration

import { application } from "./application"

import AutohideController from "./autohide_controller"
application.register("autohide", AutohideController)

import ButtonColorController from "./button_color_controller"
application.register("button-color", ButtonColorController)

import ChatController from "./chat_controller"
application.register("chat", ChatController)

import DateFieldsCommandeController from "./date_fields_commande_controller"
application.register("date-fields-commande", DateFieldsCommandeController)

import DateFieldsController from "./date_fields_controller"
application.register("date-fields", DateFieldsController)

import FormArticleController from "./form_article_controller"
application.register("form-article", FormArticleController)

import FormElementController from "./form_element_controller"
application.register("form-element", FormElementController)

import QrCodeAjoutArticleController from "./qr_code_ajout_article_controller"
application.register("qr-code-ajout-article", QrCodeAjoutArticleController)

import QrCodeController from "./qr_code_controller"
application.register("qr-code", QrCodeController)
