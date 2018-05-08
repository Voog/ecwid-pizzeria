class CreateMakeCommerceMessages < ActiveRecord::Migration
  def change
    create_table :make_commerce_messages do |t|
      t.references :payment, index: true
      t.string :app_status
      t.string :status
      t.string :message_type
      t.decimal :amount, precision: 12, scale: 2
      t.string :currency
      t.string :customer_name
      t.string :merchant_data
      t.datetime :message_time
      t.string :shop
      t.string :reference, index: true
      t.string :transaction_key, index: true
      t.string :signature
      t.string :mac
      t.text :raw_post

      t.timestamps null: false
    end
  end
end
