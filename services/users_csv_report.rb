class UsersCsvReport < BaseService

  include Callable

  attr_reader :users

  ATTRIBUTES = %i(id phone name)

  def call
    CSV.generate(headers: true) do |csv|
      csv << ATTRIBUTES
      users.each do |user|
        csv << ATTRIBUTES.map { |attr| user.send(attr) }
      end
    end
  end

end
