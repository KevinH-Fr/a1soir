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

ActiveRecord::Schema[7.1].define(version: 2024_02_23_115900) do
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
    t.index ["commande_id"], name: "index_avoir_rembs_on_commande_id"
  end

  create_table "categorie_produits", force: :cascade do |t|
    t.string "nom"
    t.text "texte_annonce"
    t.text "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.boolean "location"
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
  end

  create_table "doc_editions", force: :cascade do |t|
    t.integer "commande_id"
    t.string "doc_type"
    t.string "edition_type"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commande_id"], name: "index_doc_editions_on_commande_id"
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

  create_table "meetings", force: :cascade do |t|
    t.string "nom"
    t.date "datedebut"
    t.date "datefin"
    t.integer "commande_id", null: false
    t.integer "client_id", null: false
    t.string "lieu"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_meetings_on_client_id"
    t.index ["commande_id"], name: "index_meetings_on_commande_id"
  end

  create_table "messagemails", force: :cascade do |t|
    t.string "titre"
    t.text "body"
    t.text "commentaires"
    t.integer "commande_id"
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_messagemails_on_client_id"
    t.index ["commande_id"], name: "index_messagemails_on_commande_id"
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
    t.index ["categorie_produit_id"], name: "index_produits_on_categorie_produit_id"
    t.index ["couleur_id"], name: "index_produits_on_couleur_id"
    t.index ["fournisseur_id"], name: "index_produits_on_fournisseur_id"
    t.index ["taille_id"], name: "index_produits_on_taille_id"
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

  create_table "tailles", force: :cascade do |t|
    t.string "nom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "textes", force: :cascade do |t|
    t.string "titre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  add_foreign_key "doc_editions", "commandes"
  add_foreign_key "meetings", "clients"
  add_foreign_key "meetings", "commandes"
  add_foreign_key "messagemails", "clients"
  add_foreign_key "messagemails", "commandes"
  add_foreign_key "paiement_recus", "commandes"
  add_foreign_key "paiements", "commandes"
  add_foreign_key "produits", "categorie_produits"
  add_foreign_key "produits", "couleurs"
  add_foreign_key "produits", "fournisseurs"
  add_foreign_key "produits", "tailles"
  add_foreign_key "sousarticles", "articles"
  add_foreign_key "sousarticles", "produits"
end
