class Admin::MakeCommerceMessagesController < Admin::AdminController

  def index
    @messages = MakeCommerceMessage.paginate(page: params[:page], per_page: params[:per_page]).order('id DESC')
  end
end
