class CreateEstcardRequests < ActiveRecord::Migration
  def self.up
    create_table :estcard_requests, force: true do |t|
      t.string :action, :ver, :merchant_id, :ecuno, :eamount, :cur, :datetime, :lang
      t.timestamps
    end
  end

  def self.down
    drop_table :estcard_requests
  end
end
