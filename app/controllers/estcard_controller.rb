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
        @payment.deliver!
        PaymentResponseMailer.payment_received(message, @payment).deliver_now
        PaymentResponseMailer.payment_confirmation(message, @payment).deliver_now
        redirect_to @payment.return_path if @payment.return_path.present?
      end
      flash.now[:notice] = t('estcard.callback.success')
    else
      @payment.cancel! if @payment && !@payment.cancelled?
      flash.now[:alert] = t('estcard.callback.cancel')
    end
  end
end
