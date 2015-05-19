class PaymentResponseMailer < ActionMailer::Base

  default from: EcwidPizzeria::Application.config.app.mailer.default_from,
    reply_to: EcwidPizzeria::Application.config.app.mailer.default_from,
    return_path: Mail::Address.new(EcwidPizzeria::Application.config.app.mailer.default_from).address

  def payment_received(bank_message, payment)
    @bank_message = bank_message
    @payment = payment

    mail(to: EcwidPizzeria::Application.config.app.mailer.notification_email, subject: t('payment_response_mailer.payment_received.subject'))
  end

  def payment_confirmation(bank_message, payment)
    @bank_message = bank_message
    @payment = payment
    shop_name = EcwidPizzeria::Application.config.app.shop_name

    subject_key = EcwidPizzeria::Application.config.app.payment_confirmation_email_subject.send(I18n.locale).present? ? 'use_missing_default' : 'payment_response_mailer.payment_confirmation.subject'
    @subject = t(subject_key, shop_name: shop_name, default: EcwidPizzeria::Application.config.app.payment_confirmation_email_subject.send(I18n.locale))

    body_key = EcwidPizzeria::Application.config.app.payment_confirmation_email_body.send(I18n.locale).present? ? 'use_missing_default' : 'payment_response_mailer.payment_confirmation.default_message'
    @body_message = t(body_key,
      shop_name: shop_name, payment_description: @payment.description, amount: view_context.number_to_currency(@payment.amount, unit: @payment.currency.to_s),
      default: EcwidPizzeria::Application.config.app.payment_confirmation_email_body.send(I18n.locale)
    )

    mail(to: @payment.customer_email, subject: @subject)
  end
end
