class Payment < ActiveRecord::Base
  
  module Status
    Created = 'created'
  end
  
  validate :order_id, :amount, :presence => true
  
  before_validation :set_status, :on => :create
  
  private
  
  def set_status
    write_attribute(:status, Status::Created) if status.blank?
  end
end
