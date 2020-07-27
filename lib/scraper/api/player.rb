module Scraper
  module API
    class Player
      ROOT_PROPERTY = 'pl'.freeze
      FIRST_NAME_PROPERTY = 'fn'.freeze
      LAST_NAME_PROPERTY = 'ln'.freeze
      POSITION_PROPERTY = 'pos'.freeze
      TEAM_ID_PROPERTY = 'tid'.freeze

      URI_TEMPLATE = API::BASE_URI +
                     '%<season>s/players/playercard_%<id>i_01.json'

      attr_reader :id, :first_name, :last_name, :position, :team_id

      def self.get(id, season)
        res = nil

        # Unfortunately, the data
        # we just grabbed might be stale.
        (season..Time.zone.now.year).each do |year|
          uri = URI(format(URI_TEMPLATE, season: year, id: id))
          maybe_res = Net::HTTP.get(uri)
          res = maybe_res unless maybe_res.empty? || JSON.parse(maybe_res)['Message'] == 'Object not found.'
        end

        if res.blank? || JSON.parse(res)['Message'] == 'Object not found.'
          # This is a duplicate/corrupted player
          new(id: id,
              first_name: 'Unknown',
              last_name: 'Unknown',
              position: 'Unknown',
              team_id: DB::Team.find_or_create_by(city: 'Unknown', name: 'Unknown').id)
        else
          json = JSON.parse(res)[ROOT_PROPERTY]

          new(id: id,
              first_name: json[FIRST_NAME_PROPERTY],
              last_name: json[LAST_NAME_PROPERTY],
              position: json[POSITION_PROPERTY],
              team_id: json[TEAM_ID_PROPERTY])
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
