# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_12_01_231211) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_parameters", force: :cascade do |t|
    t.integer "tx_tva"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "coef_prix_achat_vente"
    t.integer "coef_longue_duree"
    t.integer "duree_rdv"
  end

  create_table "articles", force: :cascade do |t|
    t.integer "quantite"
    t.decimal "prix"
    t.decimal "total"
    t.integer "produit_id", null: false
    t.integer "commande_id", null: false
    t.string "locvente"
    t.decimal "caution"
    t.decimal "totalcaution"
    t.boolean "longueduree"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commande_id"], name: "index_articles_on_commande_id"
    t.index ["produit_id"], name: "index_articles_on_produit_id"
  end

  create_table "avoir_rembs", force: :cascade do |t|
    t.string "type_avoir_remb"
    t.decimal "montant"
    t.string "nature"
    t.integer "commande_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "custom_date"
    t.index ["commande_id"], name: "index_avoir_rembs_on_commande_id"
  end

  create_table "categorie_produits", force: :cascade do |t|
    t.string "nom"
    t.text "texte_annonce"
    t.text "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "service"
  end

  create_table "categorie_produits_produits", id: false, force: :cascade do |t|
    t.integer "produit_id", null: false
    t.integer "categorie_produit_id", null: false
    t.index ["categorie_produit_id"], name: "index_categorie_produits_produits_on_categorie_produit_id"
    t.index ["produit_id"], name: "index_categorie_produits_produits_on_produit_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "prenom"
    t.string "nom"
    t.text "commentaires"
    t.string "propart"
    t.string "intitule"
    t.string "tel"
    t.string "tel2"
    t.string "mail"
    t.string "mail2"
    t.string "adresse"
    t.string "cp"
    t.string "ville"
    t.string "pays"
    t.string "contact"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language", default: "fr"
  end

  create_table "commandes", force: :cascade do |t|
    t.string "nom"
    t.decimal "montant"
    t.text "description"
    t.integer "client_id", null: false
    t.date "debutloc"
    t.date "finloc"
    t.date "dateevent"
    t.string "statutarticles"
    t.string "typeevent"
    t.integer "profile_id", null: false
    t.text "commentaires"
    t.text "commentaires_doc"
    t.string "type_locvente"
    t.boolean "devis"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_commandes_on_client_id"
    t.index ["profile_id"], name: "index_commandes_on_profile_id"
  end

  create_table "couleurs", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "couleur_code"
  end

  create_table "demande_cabine_essayage_items", force: :cascade do |t|
    t.integer "demande_cabine_essayage_id", null: false
    t.integer "produit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["demande_cabine_essayage_id"], name: "idx_on_demande_cabine_essayage_id_a6b675f903"
    t.index ["produit_id"], name: "index_demande_cabine_essayage_items_on_produit_id"
  end

  create_table "demande_cabine_essayages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "demande_rdv_id"
    t.index ["demande_rdv_id"], name: "index_demande_cabine_essayages_on_demande_rdv_id"
  end

  create_table "demande_rdv", force: :cascade do |t|
    t.string "nom"
    t.string "email"
    t.string "telephone"
    t.text "commentaire"
    t.datetime "date_rdv"
    t.string "statut"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "demande_rdvs", force: :cascade do |t|
    t.string "nom"
    t.string "email"
    t.string "telephone"
    t.text "commentaire"
    t.datetime "date_rdv"
    t.string "statut"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "prenom"
    t.string "type_rdv"
    t.integer "nombre_personnes"
    t.string "evenement"
    t.date "date_evenement"
  end

  create_table "doc_editions", force: :cascade do |t|
    t.integer "commande_id"
    t.string "doc_type"
    t.string "edition_type"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sujet"
    t.string "destinataire"
    t.text "message"
    t.boolean "mail_sent"
    t.text "label_facture_simple"
    t.index ["commande_id"], name: "index_doc_editions_on_commande_id"
  end

  create_table "ensembles", force: :cascade do |t|
    t.integer "produit_id"
    t.integer "type_produit1_id"
    t.integer "type_produit2_id"
    t.integer "type_produit3_id"
    t.integer "type_produit4_id"
    t.integer "type_produit5_id"
    t.integer "type_produit6_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produit_id"], name: "index_ensembles_on_produit_id"
    t.index ["type_produit1_id"], name: "index_ensembles_on_type_produit1_id"
    t.index ["type_produit2_id"], name: "index_ensembles_on_type_produit2_id"
    t.index ["type_produit3_id"], name: "index_ensembles_on_type_produit3_id"
    t.index ["type_produit4_id"], name: "index_ensembles_on_type_produit4_id"
    t.index ["type_produit5_id"], name: "index_ensembles_on_type_produit5_id"
    t.index ["type_produit6_id"], name: "index_ensembles_on_type_produit6_id"
  end

  create_table "fournisseurs", force: :cascade do |t|
    t.string "nom"
    t.string "tel"
    t.string "mail"
    t.string "contact"
    t.string "site"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friends", force: :cascade do |t|
    t.string "nom"
    t.integer "age"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meetings", force: :cascade do |t|
    t.string "nom"
    t.datetime "datedebut"
    t.datetime "datefin"
    t.bigint "commande_id"
    t.bigint "client_id"
    t.string "lieu"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "google_calendar_event_id"
    t.integer "demande_rdv_id"
    t.index ["client_id"], name: "index_meetings_on_client_id"
    t.index ["commande_id"], name: "index_meetings_on_commande_id"
    t.index ["demande_rdv_id"], name: "index_meetings_on_demande_rdv_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "paiement_recus", force: :cascade do |t|
    t.string "typepaiement"
    t.decimal "montant"
    t.integer "commande_id", null: false
    t.string "moyen"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "custom_date"
    t.index ["commande_id"], name: "index_paiement_recus_on_commande_id"
  end

  create_table "paiements", force: :cascade do |t|
    t.string "typepaiement"
    t.decimal "montant"
    t.integer "commande_id", null: false
    t.string "moyen"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commande_id"], name: "index_paiements_on_commande_id"
  end

  create_table "parametre_rdvs", force: :cascade do |t|
    t.string "nom"
    t.integer "minutes_par_personne_supp", default: 15, null: false
    t.integer "nb_rdv_simultanes_lundi", default: 2, null: false
    t.integer "nb_rdv_simultanes_mardi", default: 2, null: false
    t.integer "nb_rdv_simultanes_mercredi", default: 2, null: false
    t.integer "nb_rdv_simultanes_jeudi", default: 2, null: false
    t.integer "nb_rdv_simultanes_vendredi", default: 2, null: false
    t.integer "nb_rdv_simultanes_samedi", default: 2, null: false
    t.integer "nb_rdv_simultanes_dimanche", default: 2, null: false
    t.string "creneaux_horaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "periodes_non_disponibles", force: :cascade do |t|
    t.date "date_debut", null: false
    t.date "date_fin", null: false
    t.boolean "recurrence", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "produits", force: :cascade do |t|
    t.string "nom"
    t.decimal "prixvente"
    t.decimal "prixlocation"
    t.text "description"
    t.integer "categorie_produit_id"
    t.decimal "caution"
    t.string "handle"
    t.string "reffrs"
    t.integer "quantite"
    t.integer "fournisseur_id"
    t.date "dateachat"
    t.decimal "prixachat"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "couleur_id"
    t.integer "taille_id"
    t.integer "type_produit_id"
    t.boolean "actif", default: true
    t.boolean "eshop"
    t.integer "poids"
    t.string "stripe_product_id"
    t.string "stripe_price_id"
    t.boolean "today_availability", default: false, null: false
    t.index ["categorie_produit_id"], name: "index_produits_on_categorie_produit_id"
    t.index ["couleur_id"], name: "index_produits_on_couleur_id"
    t.index ["fournisseur_id"], name: "index_produits_on_fournisseur_id"
    t.index ["taille_id"], name: "index_produits_on_taille_id"
    t.index ["today_availability"], name: "index_produits_on_today_availability"
    t.index ["type_produit_id"], name: "index_produits_on_type_produit_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "prenom"
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sousarticles", force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "produit_id", null: false
    t.string "nature"
    t.text "description"
    t.decimal "prix"
    t.decimal "caution"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_sousarticles_on_article_id"
    t.index ["produit_id"], name: "index_sousarticles_on_produit_id"
  end

  create_table "stripe_payment_items", force: :cascade do |t|
    t.integer "stripe_payment_id", null: false
    t.integer "produit_id", null: false
    t.integer "quantity"
    t.integer "unit_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produit_id"], name: "index_stripe_payment_items_on_produit_id"
    t.index ["stripe_payment_id"], name: "index_stripe_payment_items_on_stripe_payment_id"
  end

  create_table "stripe_payments", force: :cascade do |t|
    t.string "stripe_payment_id"
    t.integer "produit_id"
    t.integer "amount"
    t.string "currency"
    t.string "status"
    t.string "payment_method"
    t.string "charge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["produit_id"], name: "index_stripe_payments_on_produit_id"
  end

  create_table "tailles", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "textes", force: :cascade do |t|
    t.string "titre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "adresse"
    t.text "contact"
    t.text "horaire"
    t.text "boutique"
    t.text "equipe"
  end

  create_table "type_produits", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "type_rdvs", force: :cascade do |t|
    t.string "code", null: false
    t.integer "duree_base_minutes", default: 60, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_type_rdvs_on_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "commandes"
  add_foreign_key "articles", "produits"
  add_foreign_key "avoir_rembs", "commandes"
  add_foreign_key "commandes", "clients"
  add_foreign_key "commandes", "profiles"
  add_foreign_key "demande_cabine_essayage_items", "demande_cabine_essayages"
  add_foreign_key "demande_cabine_essayage_items", "produits"
  add_foreign_key "demande_cabine_essayages", "demande_rdvs"
  add_foreign_key "doc_editions", "commandes"
  add_foreign_key "ensembles", "produits"
  add_foreign_key "ensembles", "type_produits", column: "type_produit1_id"
  add_foreign_key "ensembles", "type_produits", column: "type_produit2_id"
  add_foreign_key "ensembles", "type_produits", column: "type_produit3_id"
  add_foreign_key "ensembles", "type_produits", column: "type_produit4_id"
  add_foreign_key "ensembles", "type_produits", column: "type_produit5_id"
  add_foreign_key "ensembles", "type_produits", column: "type_produit6_id"
  add_foreign_key "meetings", "clients"
  add_foreign_key "meetings", "commandes"
  add_foreign_key "meetings", "demande_rdvs"
  add_foreign_key "paiement_recus", "commandes"
  add_foreign_key "paiements", "commandes"
  add_foreign_key "produits", "categorie_produits"
  add_foreign_key "produits", "couleurs"
  add_foreign_key "produits", "fournisseurs"
  add_foreign_key "produits", "tailles"
  add_foreign_key "produits", "type_produits"
  add_foreign_key "sousarticles", "articles"
  add_foreign_key "sousarticles", "produits"
  add_foreign_key "stripe_payment_items", "produits"
  add_foreign_key "stripe_payment_items", "stripe_payments"
  add_foreign_key "stripe_payments", "produits"
end
