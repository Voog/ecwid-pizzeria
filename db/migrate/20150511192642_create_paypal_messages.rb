class CreatePaypalMessages < ActiveRecord::Migration
  def change
    create_table :paypal_messages do |t|
      t.string :payment_status, null: false
      t.string :pending_reason
      t.datetime :payment_date, null: false
      t.string :payment_fee
      t.string :payment_type
      t.string :payment_gross
      t.string :txn_id
      t.string :txn_type
      t.string :item_number
      t.string :item_name
      t.string :business
      t.string :receiver_email
      t.string :receiver_id
      t.string :invoice
      t.string :payer_id
      t.string :payer_email
      t.string :payer_status
      t.string :first_name
      t.string :last_name
      t.string :residence_country
      t.string :transaction_subject
      t.string :quantity
      t.decimal :mc_gross, precision: 12, scale: 2
      t.decimal :mc_fee, precision: 12, scale: 2
      t.string :mc_currency
      t.decimal :tax, precision: 12, scale: 2
      t.decimal :shipping, precision: 12, scale: 2
      t.decimal :handling_amount, precision: 12, scale: 2
      t.string :protection_eligibility
      t.string :notify_version
      t.string :verify_sign
      t.boolean :test_ipn, default: false
      t.string :validation_status
      t.string :custom
      t.text :request_params
      t.timestamps

      t.index :txn_id
      t.index :invoice
    end
  end
end
