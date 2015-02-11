class CreateEstcardMessages < ActiveRecord::Migration
  def self.up
    create_table :estcard_messages do |t|
      t.string :action, :ver, :merchant_id, :ecuno, :receipt_no, :eamount, :cur, :respcode, :datetime, :msgdata, :actiontext
      t.text :mac
      t.timestamps
    end
  end

  def self.down
    drop_table :estcard_messages
  end
end
