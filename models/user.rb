class User < ActiveRecord::Base
  has_many :ads
  scope :recent, -> { order("created_at DESC") }
end
