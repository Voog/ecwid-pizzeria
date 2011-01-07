class PaymentsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def create
    @payment = Payment.create!(
      :order_id => params[:ord], :description => params[:des], :amount => params[:amt],
      :frequency => params[:frq], :customer_email => params[:ceml], :return_path => params[:ret],
      :opt => params[:opt], :currency => 'EUR'
    )
    
    ipizza_payment = Ipizza::Payment.new(
      :stamp => @payment.id, :amount => @payment.amount, :refnum => @payment.order_id,
      :message => @payment.description, :currency => @payment.currency
    )
    
    @swed_request = Ipizza::Provider::Swedbank.new.payment_request(ipizza_payment)
    @seb_request = Ipizza::Provider::Seb.new.payment_request(ipizza_payment)
  end
end
