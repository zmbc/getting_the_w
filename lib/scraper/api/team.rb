module Scraper
  module API
    class Team
      ID_PROPERTY = 'tid'.freeze
      CITY_PROPERTY = 'tc'.freeze
      NAME_PROPERTY = 'tn'.freeze

      attr_reader :id, :city, :name

      def self.from_json(json)
        new(id: json[ID_PROPERTY],
            city: json[CITY_PROPERTY],
            name: json[NAME_PROPERTY])
      end

      def initialize(id: nil, city: nil, name: nil)
        @id = id
        @city = city
        @name = name
      end
    end
  end
end
