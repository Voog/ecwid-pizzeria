class Admin::PaypalMessagesController < Admin::AdminController

  def index
    @messages = PaypalMessage.paginate(page: params[:page], per_page: params[:per_page]).order('id DESC')
  end
end
