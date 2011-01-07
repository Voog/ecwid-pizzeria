class IpizzaController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def callback
    provider = load_provider
    bank_response = provider.payment_response(params)
    
    bank_message = BankMessage.create_from_params!(params, bank_response)
    payment = Payment.find(bank_message.payment_id)
    
    if bank_response.valid? and bank_response.success?
      if payment and not payment.delivered?
        payment.deliver!
        PaymentResponseMailer.payment_received(bank_message, payment).deliver
        PaymentResponseMailer.payment_confirmation(bank_message, payment).deliver
      end  
      render :action => :success
    else
      if payment and not payment.cancelled?
        payment.cancel!
      end
      render :action => :cancel
    end
  end
  
  private
  
  def load_provider
    case params[:provider]
    when 'seb'
      Ipizza::Provider::Seb.new
    when 'swedbank'
      Ipizza::Provider::Swedbank.new
    end
  end
end