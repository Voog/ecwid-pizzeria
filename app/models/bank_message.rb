class BankMessage < ActiveRecord::Base

  serialize :params

  def self.create_from_params!(params, payment_response)
    info = payment_response.payment_info
    create! do |e|
      e.provider = info.provider || params[:provider]
      e.payment_id = info.stamp
      e.snd_id = info.provider
      e.status = ((payment_response.valid? && payment_response.success?) ? 'DELIVERED' : 'PENDING')
      e.receipt_id = params['VK_REV_ID']
      e.stamp = info.stamp
      e.transaction_no = info.transaction_id
      e.amount = info.amount
      e.currency = info.currency
      e.receiver_account = info.receiver_account
      e.receiver_name = info.receiver_name
      e.sender_account = info.sender_account
      e.sender_name = info.sender_name
      e.ref_no = info.refnum
      e.message = info.message
      e.params = params
    end
  end
end
