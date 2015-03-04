class IpizzaController < ApplicationController

  skip_before_action :verify_authenticity_token

  def callback
    provider = Ipizza::Provider.get(params['VK_SND_ID'].presence || params[:provider])

    if provider.present?
      bank_response = provider.payment_response(params)

      bank_message = BankMessage.create_from_params!(params, bank_response)
      @payment = Payment.find(bank_message.payment_id)

      if bank_response.valid? && bank_response.success?
        if @payment && !@payment.delivered?
          @payment.send_store_notification! if @payment.deliver!

          begin
            PaymentResponseMailer.payment_received(bank_message, @payment).deliver_now
          rescue Exception => e
            Rails.logger.error "ERROR: PaymentResponseMailer.payment_received was failed. Payment id: #{@payment.id}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
          end

          begin
            PaymentResponseMailer.payment_confirmation(bank_message, @payment).deliver_now
          rescue Exception => e
            Rails.logger.error "ERROR: PaymentResponseMailer.payment_confirmation was failed. Payment id: #{@payment.id}: #{e.message.inspect}: \n#{e.backtrace[0..8].join("\n  ")}"
          end

          redirect_to @payment.return_path if @payment.return_path.present?
        end
        flash.now[:notice] = t('ipizza.callback.success')
      elsif bank_response.success?
        flash.now[:alert] = t('ipizza.callback.error')
        Rails.logger.error "IpizzaController.callback: BankMessage response was successful but validation fails! ID: #{bank_message.id}; payment_id: {@payment.try(:id)}"
      else
        if @payment && !@payment.cancelled?
          @payment.send_store_notification! if @payment.cancel!
        end
        flash.now[:alert] = t('ipizza.callback.cancel')
      end
    else
      flash.now[:alert] = t('ipizza.callback.error')
      Rails.logger.error "IpizzaController.callback: Provider '#{params['VK_SND_ID'].to_s}' not found!"
    end
  end
end
