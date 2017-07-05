module Scraper
  module API
    module PlayByPlay
      class Period
        class PeriodDoesNotExistError < StandardError
        end

        ROOT_PROPERTY = 'g'.freeze
        EVENTS_PROPERTY = 'pla'.freeze

        attr_reader :game, :period_num, :events

        def self.get(game, period_num)
          uri = URI("http://data.wnba.com/data/v2015/json/mobile_teams/wnba/#{game.season}/scores/pbp/#{game.id}_#{period_num}_pbp.json")
          res = Net::HTTP.get(uri)
          puts uri

          raise PeriodDoesNotExistError if res.empty?

          json = JSON.parse(res)

          events = json[ROOT_PROPERTY][EVENTS_PROPERTY].map do |play_json|
            Event.from_json play_json
          end

          new(game: game, period_num: period_num, events: events)
        end

        def initialize(game: nil, period_num: nil, events: nil)
          @game = game
          @period_num = period_num
          @events = events
        end
      end
    end
  end
end
