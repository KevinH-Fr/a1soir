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

import ProductGalleryModalController from "./product_gallery_modal_controller"
application.register("product-gallery-modal", ProductGalleryModalController)

import ReservationFormController from "./reservation_form_controller"
application.register("reservation-form", ReservationFormController)

import ScrollRevealController from "./scroll_reveal_controller"
application.register("scroll-reveal", ScrollRevealController)

import StickyTextController from "./sticky_text_controller"
application.register("sticky-text", StickyTextController)

import CookieConsentController from "./cookie_consent_controller"
application.register("cookie-consent", CookieConsentController)

import ShareListController from "./share_list_controller"
application.register("share-list", ShareListController)

import CollectionCardRevealController from "./collection_card_reveal_controller"
application.register("collection-card-reveal", CollectionCardRevealController)

import NavbarOutsideCloseController from "./navbar_outside_close_controller"
application.register("navbar-outside-close", NavbarOutsideCloseController)

import ProduitsSearchController from "./produits_search_controller"
application.register("produits-search", ProduitsSearchController)
