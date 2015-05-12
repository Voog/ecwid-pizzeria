class EstcardController < ApplicationController

  skip_before_action :verify_authenticity_token

  # {"auto"=>"N", "datetime"=>"20120613111615", "eamount"=>"2700", "id"=>"Mileedi", "ver"=>"2",
  # "controller"=>"estcard", "receipt_no"=>"00245", "mac"=>"35DA16420...157F8", "actiontext"=>"OK",
  # "msgdata"=>"nipitiri", "respcode"=>"000", "cur"=>"EUR", "action"=>"callback", "ecuno"=>"10700000",
  # "submitbtn"=>"Tagasi kaupmehe juurde"}
  def callback
    message = EstcardMessage.create do |e|
      e.action = params[:action]
      e.ver = params[:ver]
      e.merchant_id = params[:id]
      e.ecuno = params[:ecuno]
      e.receipt_no = params[:receipt_no]
      e.eamount = params[:eamount]
      e.cur = params[:cur]
      e.respcode = params[:respcode]
      e.datetime = params[:datetime]
      e.msgdata = params[:msgdata]
      e.actiontext = params[:actiontext]
      e.mac = params[:mac]
    end

    @payment = Payment.find_by_id(message.payment_id)

    if message.valid_mac? && message.success?
      if @payment && !@payment.delivered?
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
      flash.now[:notice] = t('shared.callback.success')
    elsif message.success?
      flash.now[:alert] = t('shared.callback.error')
      Rails.logger.error "EstcardController.callback: EstcardMessage response was successful but validation fails! ID: #{message.id}; payment_id: #{@payment.try(:id)}"
    else
      if @payment && !@payment.cancelled?
        @payment.send_store_notification! if @payment.cancel!
      end
      flash.now[:alert] = t('shared.callback.cancel')
    end

    redirect_to @payment.store_return_url if @payment && @payment.delivered? && @payment.store_return_url.present? && params[:auto] != 'Y'
  end
end
