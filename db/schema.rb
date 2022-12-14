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

ActiveRecord::Schema[7.0].define(version: 2022_10_14_093537) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "annonces", force: :cascade do |t|
    t.text "principale"
    t.text "soiree"
    t.text "mariee"
    t.text "homme"
    t.text "accessoire"
    t.text "deguisement"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "articleoptions", force: :cascade do |t|
    t.string "nature"
    t.text "description"
    t.decimal "prix"
    t.decimal "caution"
    t.string "taille"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "article_id"
    t.index ["article_id"], name: "index_articleoptions_on_article_id"
  end

  create_table "articles", force: :cascade do |t|
    t.integer "quantite"
    t.bigint "commande_id"
    t.bigint "produit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "prix"
    t.decimal "total"
    t.index ["commande_id"], name: "index_articles_on_commande_id"
    t.index ["produit_id"], name: "index_articles_on_produit_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "nom"
    t.string "mail"
    t.text "commentaires"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "commandes", force: :cascade do |t|
    t.string "nom"
    t.decimal "montant"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.index ["client_id"], name: "index_commandes_on_client_id"
  end

  create_table "friends", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "labels", force: :cascade do |t|
    t.text "principale"
    t.text "soiree"
    t.text "mariee"
    t.text "homme"
    t.text "accessoire"
    t.text "deguisement"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "modelsousarticles", force: :cascade do |t|
    t.string "nature"
    t.text "description"
    t.decimal "prix"
    t.decimal "caution"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "paiements", force: :cascade do |t|
    t.string "typepaiement"
    t.decimal "montant"
    t.bigint "commande_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nature"
    t.index ["commande_id"], name: "index_paiements_on_commande_id"
  end

  create_table "posts", force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantite"
  end

  create_table "produits", force: :cascade do |t|
    t.string "nom"
    t.decimal "prix"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "categorie"
    t.boolean "vitrine"
    t.string "couleur"
  end

  create_table "sousarticles", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.string "nature"
    t.text "description"
    t.decimal "prix_sousarticle"
    t.decimal "caution"
    t.string "taille"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_sousarticles_on_article_id"
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
  add_foreign_key "articleoptions", "articles"
  add_foreign_key "articles", "commandes"
  add_foreign_key "articles", "produits"
  add_foreign_key "commandes", "clients"
  add_foreign_key "paiements", "commandes"
  add_foreign_key "sousarticles", "articles"
end
