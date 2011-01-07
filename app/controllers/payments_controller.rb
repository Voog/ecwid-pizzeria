class PaymentsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def create
    pmt = Payment.create!(
      :order_id => params[:ord], :description => params[:des], :amount => params[:amt],
      :frequency => params[:frq], :customer_email => params[:ceml], :return_path => params[:ret],
      :opt => params[:opt]
    )
    
    @payment = Ipizza::Payment.new(
      :stamp => pmt.id, :amount => pmt.amount, :refnum => pmt.order_id,
      :message => pmt.description, :currency => 'EUR'
    )
    
    @swed_request = Ipizza::Provider::Swedbank.new.payment_request(@payment)
    @seb_request = Ipizza::Provider::Seb.new.payment_request(@payment)
  end
end
