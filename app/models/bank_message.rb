class BankMessage < ActiveRecord::Base
  
  serialize :params
  
  def self.create_from_params!(params, payment_response)
    create!(
      :provider => params['VK_SND_ID'], :payment_id => params['VK_STAMP'], :snd_id => params['VK_SND_ID'],
      :status => ((payment_response.valid? && payment_response.success?) ? 'DELIVERED' : 'PENDING'),
      :receipt_id => params['VK_REV_ID'], :stamp => params['VK_STAMP'], :transaction_no => params['VK_T_NO'],
      :amount => params['VK_AMOUNT'], :currency => params['VK_CURR'], :receiver_account => params['VK_REC_ACC'],
      :receiver_name => params['VK_REC_NAME'], :sender_account => params['VK_SND_ACC'],
      :sender_name => params['VK_SND_NAME'], :ref_no => params['VK_REF'], :message => params['VK_MSG'],
      :params => params
    )
  end
end
