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

ActiveRecord::Schema[8.1].define(version: 2026_03_29_120001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 50, null: false
    t.string "first_name", limit: 50, null: false
    t.string "last_name", limit: 50, null: false
    t.string "password_digest", null: false
    t.string "phone_number", limit: 10, null: false
    t.string "role", default: "customer", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
  end

  create_table "users_authentification", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.boolean "remember_me", default: false, null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["expires_at"], name: "index_users_authentification_on_expires_at"
    t.index ["token_digest"], name: "index_users_authentification_on_token_digest", unique: true
    t.index ["user_id"], name: "index_users_authentification_on_user_id"
  end

  add_foreign_key "users_authentification", "users"
end
