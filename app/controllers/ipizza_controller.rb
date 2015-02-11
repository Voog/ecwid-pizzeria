class IpizzaController < ApplicationController

  skip_before_action :verify_authenticity_token

  def callback
    provider = Ipizza::Provider.get(params['VK_SND_ID'].to_s)

    if provider.present?
      bank_response = provider.payment_response(params)

      bank_message = BankMessage.create_from_params!(params, bank_response)
      @payment = Payment.find(bank_message.payment_id)

      if bank_response.valid? && bank_response.success?
        if @payment && !@payment.delivered?
          @payment.deliver!
          PaymentResponseMailer.payment_received(bank_message, @payment).deliver_now
          PaymentResponseMailer.payment_confirmation(bank_message, @payment).deliver_now
          redirect_to @payment.return_path if @payment.return_path.present?
        end
        flash.now[:notice] = t('ipizza.callback.success')
      else
        @payment.cancel! if @payment && !@payment.cancelled?
        flash.now[:alert] = t('ipizza.callback.cancel')
      end
    else
      flash.now[:alert] = t('ipizza.callback.error')
      Rails.logger.error "IpizzaController.callback: Provider '#{params['VK_SND_ID'].to_s}' not found!"
    end
  end
end
