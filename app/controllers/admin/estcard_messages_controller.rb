class Admin::EstcardMessagesController < Admin::AdminController

  def index
    @messages = EstcardMessage.paginate(page: params[:page], per_page: params[:per_page]).order('id DESC')
  end
end
