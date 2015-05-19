# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150511192642) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "bank_messages", force: :cascade do |t|
    t.string   "provider",         limit: 255,                          null: false
    t.string   "status",           limit: 255,                          null: false
    t.integer  "payment_id"
    t.integer  "snd_id"
    t.integer  "receipt_id"
    t.string   "stamp",            limit: 255
    t.string   "transaction_no",   limit: 255
    t.decimal  "amount",                       precision: 10, scale: 2
    t.string   "currency",         limit: 255
    t.string   "receiver_account", limit: 255
    t.string   "receiver_name",    limit: 255
    t.string   "sender_account",   limit: 255
    t.string   "sender_name",      limit: 255
    t.string   "ref_no",           limit: 255
    t.string   "message",          limit: 255
    t.text     "params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "estcard_messages", force: :cascade do |t|
    t.string   "action",      limit: 255
    t.string   "ver",         limit: 255
    t.string   "merchant_id", limit: 255
    t.string   "ecuno",       limit: 255
    t.string   "receipt_no",  limit: 255
    t.string   "eamount",     limit: 255
    t.string   "cur",         limit: 255
    t.string   "respcode",    limit: 255
    t.string   "datetime",    limit: 255
    t.string   "msgdata",     limit: 255
    t.string   "actiontext",  limit: 255
    t.text     "mac"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "estcard_requests", force: :cascade do |t|
    t.string   "action",      limit: 255
    t.string   "ver",         limit: 255
    t.string   "merchant_id", limit: 255
    t.string   "ecuno",       limit: 255
    t.string   "eamount",     limit: 255
    t.string   "cur",         limit: 255
    t.string   "datetime",    limit: 255
    t.string   "lang",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "order_id",                                            null: false
    t.string   "description",    limit: 255
    t.decimal  "amount",                     precision: 10, scale: 2, null: false
    t.string   "frequency",      limit: 255
    t.string   "customer_email", limit: 255
    t.string   "return_path",    limit: 255
    t.string   "opt",            limit: 255
    t.string   "status",         limit: 255,                          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency",       limit: 255
  end

  create_table "paypal_messages", force: :cascade do |t|
    t.string   "payment_status",                                                  null: false
    t.string   "pending_reason"
    t.datetime "payment_date",                                                    null: false
    t.string   "payment_fee"
    t.string   "payment_type"
    t.string   "payment_gross"
    t.string   "txn_id"
    t.string   "txn_type"
    t.string   "item_number"
    t.string   "item_name"
    t.string   "business"
    t.string   "receiver_email"
    t.string   "receiver_id"
    t.string   "invoice"
    t.string   "payer_id"
    t.string   "payer_email"
    t.string   "payer_status"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "residence_country"
    t.string   "transaction_subject"
    t.string   "quantity"
    t.decimal  "mc_gross",               precision: 12, scale: 2
    t.decimal  "mc_fee",                 precision: 12, scale: 2
    t.string   "mc_currency"
    t.decimal  "tax",                    precision: 12, scale: 2
    t.decimal  "shipping",               precision: 12, scale: 2
    t.decimal  "handling_amount",        precision: 12, scale: 2
    t.string   "protection_eligibility"
    t.string   "notify_version"
    t.string   "verify_sign"
    t.boolean  "test_ipn",                                        default: false
    t.string   "validation_status"
    t.string   "custom"
    t.text     "request_params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "paypal_messages", ["invoice"], name: "index_paypal_messages_on_invoice", using: :btree
  add_index "paypal_messages", ["txn_id"], name: "index_paypal_messages_on_txn_id", using: :btree

end
