class PaymentsController < ApplicationController
  
  skip_before_filter :verify_authenticity_token
  
  def create
    render :text => params.inspect
  end
end
