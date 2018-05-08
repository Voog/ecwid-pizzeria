class MakeCommerceMessage < ActiveRecord::Base
  module AppStatus
    Success = 'success'.freeze
    Cancelled = 'cancelled'.freeze
    Pending = 'pending'.freeze
    Refunded = 'refunded'.freeze
    Voided = 'voided'.freeze
    Other = 'other'.freeze
    Invalid = 'invalid'.freeze

    def self.values
      [Success, Cancelled, Pending, Refunded, Voided, Other, Invalid]
    end
  end

  belongs_to :payment

  def success?
    app_status == AppStatus::Success
  end

  def pending?
    app_status == AppStatus::Pending
  end

  def cancelled?
    app_status == AppStatus::Cancelled
  end
end
