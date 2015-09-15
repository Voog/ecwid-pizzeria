class PaypalController < ApplicationController

  skip_before_action :verify_authenticity_token

  def callback
    response = if request.raw_post.blank? && params.key?(:tx) && params[:st] == 'Completed'
      'PDT_COMPLETED'
    else
      validate_ipn_notification(request.raw_post)
    end
    message = PaypalMessage.log(params.merge(validation_status: response))
    @payment = Payment.find_by_id(message.ipn_message? ? message.invoice : message.transaction_subject)

    case response
    when 'PDT_COMPLETED'
      flash.now[:notice] = @payment && @payment.delivered? ? t('shared.callback.success') : t('shared.callback.pending')
    when "VERIFIED"
      if message.success?
        if @payment && !@payment.delivered? && message.completed?
          @payment.send_store_notification! if @payment.deliver!

          begin
            PaymentResponseMailer.payment_received(message, @payment).deliver_now
          rescue Exception => e
            Rails.logger.error "ERROR: PaymentResponseMailer.payment_received was failed. Payment id: #{@payment.id}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
          end

          begin
            PaymentResponseMailer.payment_confirmation(message, @payment).deliver_now
          rescue Exception => e
            Rails.logger.error "ERROR: PaymentResponseMailer.payment_confirmation was failed. Payment id: #{@payment.id}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
          end
        end
        flash.now[:notice] = message.pending? ? t('shared.callback.pending') : t('shared.callback.success')
      else
        if @payment && !@payment.cancelled?
          @payment.send_store_notification! if @payment.cancel!
        end
        flash.now[:alert] = t('shared.callback.cancel')
      end
    else
      flash.now[:alert] = t('shared.callback.error')
      Rails.logger.error "PaypalController.callback: PayPal IPN validation was failed! ID: #{message.try(:id)}; payment_id: #{@payment.try(:id)}"
    end

    redirect_to @payment.store_return_url if @payment && @payment.delivered? && @payment.store_return_url.present? && !params.key?(:ipn_track_id) && message.ipn_message?
  end

  private

  def validate_ipn_notification(raw)
    uri = URI.parse("#{EcwidPizzeria::Application.config.paypal.service_url}?cmd=_notify-validate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.post(
      uri.request_uri,
      raw,
      'Content-Length' => "#{raw.size}",
       'User-Agent' => "Ruby"
    ).body

  rescue Exception => e
    Rails.logger.error "PaypalController.validate_ipn_notification ERROR: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
    'ERROR'
  end
end
