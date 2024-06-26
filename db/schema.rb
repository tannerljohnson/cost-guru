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

ActiveRecord::Schema[7.1].define(version: 2024_04_27_175055) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "account_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "membership_invitation_id"
    t.uuid "account_id", null: false
    t.uuid "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_memberships_on_account_id"
    t.index ["membership_invitation_id"], name: "index_account_memberships_on_membership_invitation_id"
    t.index ["user_id"], name: "index_account_memberships_on_user_id"
  end

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "iam_access_key_id"
    t.string "iam_secret_access_key"
    t.string "role_arn"
    t.string "access_key_id"
    t.string "secret_access_key"
    t.string "session_token"
    t.string "credentials_expire_at"
    t.index ["user_id"], name: "index_accounts_on_user_id"
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

  create_table "analyses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "account_id"
    t.float "enterprise_cross_service_discount", default: 0.0, null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.float "optimal_hourly_commit"
    t.string "granularity", default: "HOURLY", null: false
    t.jsonb "chart_data", default: {}, null: false
    t.integer "commitment_years", default: 3, null: false
    t.string "group_by", default: "NONE", null: false
    t.index ["account_id"], name: "index_analyses_on_account_id"
  end

  create_table "contract_year_service_discounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "service_discount_id"
    t.uuid "contract_year_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_year_id"], name: "index_contract_year_service_discounts_on_contract_year_id"
    t.index ["service_discount_id"], name: "index_contract_year_service_discounts_on_service_discount_id"
  end

  create_table "contract_years", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.decimal "spend_commitment", null: false
    t.uuid "contract_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_contract_years_on_contract_id"
  end

  create_table "contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "term_start", null: false
    t.datetime "term_end", null: false
    t.decimal "cross_service_discount", null: false
    t.decimal "upfront_payment_discount", null: false
    t.uuid "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_contracts_on_account_id"
  end

  create_table "cost_and_usages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start", null: false
    t.uuid "analysis_id", null: false
    t.string "filter", null: false
    t.float "total", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "groups", default: []
    t.index ["analysis_id"], name: "index_cost_and_usages_on_analysis_id"
  end

  create_table "membership_invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "invited_by", null: false
    t.uuid "account_id", null: false
    t.string "email", null: false
    t.string "status", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "invited_user_id"
    t.index ["account_id"], name: "index_membership_invitations_on_account_id"
  end

  create_table "revenue_months", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "start_date", null: false
    t.float "revenue", default: 0.0, null: false
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "start_date"], name: "index_revenue_months_on_account_id_and_start_date", unique: true
    t.index ["account_id"], name: "index_revenue_months_on_account_id"
  end

  create_table "service_discounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "service", null: false
    t.jsonb "regions", default: [], null: false
    t.string "usage_type", null: false
    t.decimal "price", null: false
    t.string "price_unit", null: false
    t.uuid "contract_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_service_discounts_on_contract_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
