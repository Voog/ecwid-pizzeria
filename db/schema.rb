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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110107094555) do

  create_table "bank_messages", :force => true do |t|
    t.string   "provider",                                        :null => false
    t.boolean  "status",                                          :null => false
    t.integer  "payment_id"
    t.integer  "snd_id"
    t.integer  "receipt_id"
    t.string   "stamp"
    t.string   "transaction_no"
    t.decimal  "amount",           :precision => 10, :scale => 2
    t.string   "currency"
    t.string   "receiver_account"
    t.string   "receiver_name"
    t.string   "sender_account"
    t.string   "sender_name"
    t.string   "ref_no"
    t.string   "message"
    t.text     "params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer  "order_id",       :null => false
    t.string   "description"
    t.float    "amount",         :null => false
    t.string   "frequency"
    t.string   "customer_email"
    t.string   "return_path"
    t.string   "opt"
    t.string   "status",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "currency"
  end

end
