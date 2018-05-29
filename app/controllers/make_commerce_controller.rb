class MakeCommerceController < ApplicationController

  skip_before_action :verify_authenticity_token

  def callback
    notification = ::MakeCommerce::ParsingService.new(
      payload: payload,
      system_notificaton: params[:action_kind] == 'notification',
      cancelled_by_customer: params[:action_kind] == 'cancel',
      returned_by_customer: params[:action_kind] == 'return'
    )
    notification.handle!

    @payment = notification.message.try(:payment)

    case notification.message.try(:app_status)
    when MakeCommerceMessage::AppStatus::Success
      if !@payment.try(:delivered?)
        @payment.send_store_notification! if @payment.deliver!

        begin
          PaymentResponseMailer.payment_received(notification.message, @payment).deliver_now
        rescue Exception => e
          Rails.logger.error "ERROR: PaymentResponseMailer.payment_received was failed. Payment id: #{@payment.id}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
        end

        begin
          PaymentResponseMailer.payment_confirmation(notification.message, @payment).deliver_now if EcwidPizzeria::Application.config.app.payment_confirmation_email_enabled
        rescue Exception => e
          Rails.logger.error "ERROR: PaymentResponseMailer.payment_confirmation was failed. Payment id: #{@payment.id}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
        end
      end

      flash.now[:notice] = t('shared.callback.success')
    when MakeCommerceMessage::AppStatus::Cancelled
      if !@payment.try(:cancelled?)
        @payment.send_store_notification! if @payment.cancel!
      end

      flash.now[:alert] = t('shared.callback.cancel')
    when MakeCommerceMessage::AppStatus::Pending
      flash.now[:notice] = if @payment.try(:delivered?)
        t('shared.callback.success')
      elsif @payment.try(:cancelled?)
        t('shared.callback.cancel')
      else
        t('shared.callback.pending')
      end
    end

    if !notification.system_notificaton? && @payment && @payment.delivered? && @payment.store_return_url.present?
      redirect_to @payment.store_return_url
    end
  end

  private

  def payload
    params.reject { |k, _| %w(controller action action_kind).include?(k.to_s) }.tap do |h|
      h[:raw_post] = params[:json] if params[:json].present?
    end
  end
end
