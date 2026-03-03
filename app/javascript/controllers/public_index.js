// Controllers chargés uniquement sur les pages publiques
// Ne PAS inclure les controllers admin-only (qr-code, form-article, etc.)

import { application } from "./application"

import AutohideController from "./autohide_controller"
application.register("autohide", AutohideController)

import BoutiqueTextScrollController from "./boutique_text_scroll_controller"
application.register("boutique-text-scroll", BoutiqueTextScrollController)

import CalendarPickerController from "./calendar_picker_controller"
application.register("calendar-picker", CalendarPickerController)

import CarouselController from "./carousel_controller"
application.register("carousel", CarouselController)

import ChatController from "./chat_controller"
application.register("chat", ChatController)

import PlaceholderCardController from "./placeholder_card_controller"
application.register("placeholder-card", PlaceholderCardController)

import ProductGalleryModalController from "./product_gallery_modal_controller"
application.register("product-gallery-modal", ProductGalleryModalController)

import ReservationFormController from "./reservation_form_controller"
application.register("reservation-form", ReservationFormController)

import ScrollRevealController from "./scroll_reveal_controller"
application.register("scroll-reveal", ScrollRevealController)

import StickyTextController from "./sticky_text_controller"
application.register("sticky-text", StickyTextController)
