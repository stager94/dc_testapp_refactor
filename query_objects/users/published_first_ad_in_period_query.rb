module Users
  class PublishedFirstAdInPeriodQuery < BaseQuery

    attr_accessor :date_from, :date_to

    def all
      scope.recent
           .joins(:ads)
           .group('ads.user_id')
           .where('published_ads_count = 1')
           .where(ads: { published_at: published_at_period })
    end

    private

    def parsed_date_from
      Date.parse date_from
    end

    def parsed_date_to
      Date.parse date_to
    end

    def published_at_period
      (parsed_date_from..parsed_date_to)
    end

  end
end
