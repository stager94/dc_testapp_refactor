class PromoMessagesController < ApplicationController

  def new
    @promo_message = PromoMessage.new
  end

  def create
    @promo_message = PromoMessage.new(promo_message_params)

    if @promo_message.save
      @promo_message.deliver_messages!
      redirect_to promo_messages_path, notice: "Messages Sent Successfully!"
    else
      render :new
    end
  end

  def download_csv
    users = Users::PublishedFirstAdInPeriodQuery.new(scope: User, date_from: params[:date_from], date_to: params[:date_to]).all
    csv = UsersCsvReport.call(users: users)
    send_data csv, filename: "promotion-users-#{Time.zone.today}.csv"
  end

  private

  def promo_message_params
    params.require(:promo_message).permit(:body, :date_from, :date_to)
  end

end
