module Scraper
  module API
    class MonthSchedule
      module Pre2015
        GAMES_PROPERTY = 'scd'
      end
      ROOT_PROPERTY = 'mscd'.freeze
      GAMES_PROPERTY = 'g'.freeze

      URI_TEMPLATE = API::BASE_URI +
                     '%<season>s/league/10_league_schedule_%<month>s.json'

      MONTHS = 1..12

      attr_reader :season, :month, :games

      def self.get_all_from_season(season: nil)
        schedules = []
        MONTHS.each do |month|
          schedule = get(season: season, month: month)
          schedules.push schedule
        end
        schedules
      end

      def self.get(season: nil, month: nil)
        uri = URI(
          format(
            URI_TEMPLATE,
            season: season.to_s,
            month: month.to_s.rjust(2, '0')
          )
        )
        response = Net::HTTP.get(uri)
        json = JSON.parse(response)

        # Before 2015, off-season months had only a 'scd' property
        return new(season: season,
                   month: month,
                   games: []) if json['scd'] == [] && !json[ROOT_PROPERTY]

        games = json[ROOT_PROPERTY][GAMES_PROPERTY].map do |game_json|
          API::Game.from_json game_json, season
        end
        new(season: season,
            month: month,
            games: games)
      end

      def initialize(season: nil, month: nil, games: nil)
        @season = season
        @month = month
        @games = games
      end
    end
  end
end
