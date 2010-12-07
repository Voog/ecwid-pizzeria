class IpizzaController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def callback
    seb_provider = Ipizza::Provider::Seb.new
    response = seb_provider.payment_response(params)
    
    render :text => params.inspect
  end
end