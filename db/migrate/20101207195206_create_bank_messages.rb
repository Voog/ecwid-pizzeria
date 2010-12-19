class CreateBankMessages < ActiveRecord::Migration
  def self.up
    create_table :bank_messages do |t|
      t.string :provider, :null => false
      t.string :status, :null => false
      t.integer :payment_id
      t.integer :snd_id
      t.integer :receipt_id
      t.string :stamp
      t.string :transaction_no
      t.decimal :amount, :precision => 10, :scale => 2
      t.string :currency
      t.string :receiver_account
      t.string :receiver_name
      t.string :sender_account
      t.string :sender_name
      t.string :ref_no
      t.string :message
      t.text :params

      t.timestamps
    end
  end

  def self.down
    drop_table :bank_messages
  end
end
