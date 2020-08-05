module Scraper
  module API
    class Player
      @season_responses = {}

      FIRST_NAME_PROPERTY = 'fn'.freeze
      LAST_NAME_PROPERTY = 'ln'.freeze
      POSITION_PROPERTY = 'pos'.freeze
      TEAM_ID_PROPERTY = 'tid'.freeze

      URI_TEMPLATE = API::BASE_URI +
                     '%<season>s/players/10_player_info.json'

      attr_reader :id, :first_name, :last_name, :position, :team_id

      def self.get(id, season)
        player_json = nil

        (season..Time.zone.now.year).each do |year|
          unless @season_responses.key?(season)
            Utility.wait_a_sec
            response = Net::HTTP.get(URI(format(URI_TEMPLATE, season: year)))
            @season_responses[season] = JSON.parse(response)['pls']['pl']
          end

          player_json = @season_responses[season].find { |p| p['pid'] == id }
        end

        if player_json.nil?
          # This is a duplicate/corrupted player
          new(id: id,
              first_name: 'Unknown',
              last_name: 'Unknown',
              position: 'Unknown',
              team_id: DB::Team.find_or_create_by(city: 'Unknown', name: 'Unknown').id)
        else
          new(id: id,
              first_name: player_json[FIRST_NAME_PROPERTY],
              last_name: player_json[LAST_NAME_PROPERTY],
              position: player_json[POSITION_PROPERTY],
              team_id: player_json[TEAM_ID_PROPERTY])
        end
      end

      def initialize(id: nil, first_name: nil, last_name: nil, position: nil, team_id: nil)
        @id = id
        @first_name = first_name
        @last_name = last_name
        @position = position
        @team_id = team_id
      end
    end
  end
end
