class Paypal

  attr_accessor :business, :email, :invoice, :amount, :custom, :item_name, :item_number, :currency_code, :quantity, :cmd, :return, :notify_url, :cancel_return

  def initialize(params)
    @business = EcwidPizzeria::Application.config.paypal.login
    @email = params[:email]
    @invoice = params[:invoice]
    @amount = params[:amount]
    @custom = params[:custom]
    @item_name = params[:item_name]
    @currency_code = params[:currency]
    @cmd = params.fetch(:cmd, '_xclick')
    @notify_url = params.fetch(:notify_url, EcwidPizzeria::Application.config.paypal.notify_url)
    @return = params.fetch(:return, EcwidPizzeria::Application.config.paypal.return_url)
    @cancel_return = EcwidPizzeria::Application.config.app.shop_external_return_url
  end
end
