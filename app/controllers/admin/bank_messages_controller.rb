class Admin::BankMessagesController < Admin::AdminController

  def index
    @messages = BankMessage.paginate(page: params[:page], per_page: params[:per_page]).order('id DESC')
  end

  def show
    @message = BankMessage.find(params[:id])
  end
end
