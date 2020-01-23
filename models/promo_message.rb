class PromoMessage < ApplicationRecord

  validates :date_from, :date_to, :body, presence: true

  def deliver_messages!
    PromoMessageSender.call(promo_message: self)
  end

end
