class PaymentResponseMailer < ActionMailer::Base
  
  default :from => EcwidPizzeria.config.mailer.from
  
  def payment_received(bank_message, payment)
    @bank_message = bank_message
    @payment = payment
    
    mail(:to => EcwidPizzeria.config.mailer.to, :subject => I18n.t('payment_response_mailer.payment_received.subject'))
  end
  
  def payment_confirmation(bank_message, payment)
    @bank_message = bank_message
    @payment = payment
    
    mail(:to => @payment.customer_email, :subject => I18n.t('payment_response_mailer.payment_confirmation.subject'))
  end
end
