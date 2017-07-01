module Scraper
  module API
    class Game
      ID_PROPERTY = 'gid'.freeze
      HOME_PROPERTY = 'h'.freeze
      AWAY_PROPERTY = 'v'.freeze
      DATE_PROPERTY = 'gdte'.freeze

      attr_reader :id, :home_team, :away_team, :date, :season

      def self.from_json(json, season)
        home_json = json[HOME_PROPERTY]
        away_json = json[AWAY_PROPERTY]
        date = Date.parse(json[DATE_PROPERTY])
        new(id: json[ID_PROPERTY],
            home_team: API::Team.from_json(home_json),
            away_team: API::Team.from_json(away_json),
            date: date,
            season: season)
      end

      def initialize(id: nil, home_team: nil, away_team: nil, date: nil, season: nil)
        @id = id
        @home_team = home_team
        @away_team = away_team
        @date = date
        @season = season
      end
    end
  end
end
