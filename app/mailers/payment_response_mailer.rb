class PaymentResponseMailer < ActionMailer::Base
  default :from => "store@mileedi.ee"
  
  def payment_received(bank_message, payment)
    @payment = payment
    @bank_message = bank_message
    
    mail(:to => 'store@mileedi.ee', :from => "Mileedi e-Pood <store@mileedi.ee>", :subject => 'Payment')
  end
  
end
