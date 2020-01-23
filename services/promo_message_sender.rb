class PromoMessageSender < BaseService

  include Callable

  attr_reader :promo_message

  def call
    users.each &method(:send_message)
  end

  private

  def users
    @users ||= Users::PublishedFirstAdInPeriodQuery.new(scope: User, date_from: promo_message.date_from, date_to: promo_message.date_to).all
  end

  def send_message(user)
    PromoMessagesSendJob.perform_later(user.phone, promo_message)
  end

end
