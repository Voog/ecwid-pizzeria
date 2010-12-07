class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer :order_id, :null => false
      t.string :description
      t.decimal :amount, :null => false, :precision => 10, :scale => 2
      t.string :frequency
      t.string :customer_email
      t.string :return_path
      t.string :opt
      t.string :status, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
