class Payment < ActiveRecord::Base

  module Status
    Cancelled = 'cancelled'
    Created = 'created'
    Delivered = 'delivered'
  end

  validates :order_id, :amount, presence: true

  before_validation :set_status, on: :create

  def delivered?
    Status::Delivered == status
  end

  def deliver!
    update_attribute(:status, Status::Delivered)
  end

  def cancelled?
    Status::Cancelled == status
  end

  def cancel!
    update_attribute(:status, Status::Cancelled)
  end

  private

  def set_status
    write_attribute(:status, Status::Created) if status.blank?
  end
end
