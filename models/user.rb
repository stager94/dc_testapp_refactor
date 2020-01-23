class User < ApplicationRecord

  has_many :ads
  scope :recent, -> { order("created_at DESC") }

end
