module Scraper
  module API
    module PlayByPlay
      class Game
        attr_reader :periods, :game

        def self.get(game)
          periods = []
          # Handles up to 6 overtimes
          (1..10).each do |period_num|
            begin
              period = Period.get game, period_num
            rescue Period::PeriodDoesNotExistError
              # We've reached the end of the game
              break
            end

            periods.push period
            Utility.wait_a_sec
          end

          new(game: game, periods: periods)
        end

        def initialize(game: nil, periods: [])
          @game = game
          @periods = periods
        end
      end
    end
  end
end
