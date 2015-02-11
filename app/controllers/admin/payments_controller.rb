class Admin::PaymentsController < Admin::AdminController

  def index
    @payments = Payment.paginate(page: params[:page], per_page: params[:per_page]).order('id DESC')
  end
end
