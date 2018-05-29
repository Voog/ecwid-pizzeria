class CreateMakeCommerceRequests < ActiveRecord::Migration
  def change
    create_table :make_commerce_requests do |t|
      t.references :payment, index: true
      t.string :external_transaction_key, index: true
      t.string :payment_method

      t.timestamps null: false
    end
  end
end
