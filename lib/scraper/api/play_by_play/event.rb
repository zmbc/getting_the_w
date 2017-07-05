module Scraper
  module API
    module PlayByPlay
      class Event
        PLAYER_ID_PROPERTY = 'pid'.freeze
        OPPOSING_PLAYER_ID_PROPERTY = 'opid'.freeze
        EXTRA_PLAYER_ID_PROPERTY = 'epid'.freeze
        TEAM_ID_PROPERTY = 'tid'.freeze
        TYPE_PROPERTY = 'etype'.freeze
        FOUL_TYPE_PROPERTY = 'mtype'.freeze
        INDEX_PROPERTY = 'evt'.freeze
        LOC_X_PROPERTY = 'locX'.freeze
        LOC_Y_PROPERTY = 'locY'.freeze
        CLOCK_PROPERTY = 'cl'.freeze
        THREE_PROPERTY = 'opt1'.freeze
        THREE_TRUE = 1

        TYPE_CODES = {
          1 => :made_shot,
          2 => :missed_shot,
          6 => :foul,
          8 => :substitution,
          10 => :jump_ball,
          11 => :ejection
        }.freeze

        FOUL_TYPE_CODES = {
          11 => :technical
        }.freeze

        attr_reader :player_id, :opposing_player_id, :extra_player_id, :team_id,
                    :type, :index, :loc_x, :loc_y, :seconds_remaining

        def self.from_json(json)
          player_id = Utility.correct_player_id(json[PLAYER_ID_PROPERTY])
          opposing_player_id = Utility.correct_player_id(json[OPPOSING_PLAYER_ID_PROPERTY])
          extra_player_id = Utility.correct_player_id(json[EXTRA_PLAYER_ID_PROPERTY])

          type = TYPE_CODES[json[TYPE_PROPERTY]]
          foul_type = FOUL_TYPE_CODES[json[FOUL_TYPE_PROPERTY]]

          if type == :substitution && (!player_id || !extra_player_id)
            puts json
          end

          seconds_remaining = clock_to_seconds(json[CLOCK_PROPERTY])
          new(player_id: player_id,
              opposing_player_id: opposing_player_id,
              extra_player_id: extra_player_id,
              team_id: json[TEAM_ID_PROPERTY],
              type: type,
              foul_type: foul_type,
              index: Utility.to_i_or_nil(json[INDEX_PROPERTY], allow_zero: true),
              loc_x: Utility.to_i_or_nil(json[LOC_X_PROPERTY], allow_zero: true),
              loc_y: Utility.to_i_or_nil(json[LOC_Y_PROPERTY], allow_zero: true),
              seconds_remaining: seconds_remaining,
              three: (json[THREE_PROPERTY] == THREE_TRUE))
        end

        private_class_method def self.clock_to_seconds(clock_string)
          minutes, seconds = clock_string.split(':').map(&:to_i)
          (minutes * 60) + seconds
        end

        def initialize(
              player_id: nil,
              opposing_player_id: nil,
              extra_player_id: nil,
              team_id: nil,
              type: nil,
              foul_type: nil,
              index: nil,
              loc_x: nil,
              loc_y: nil,
              seconds_remaining: nil,
              three: nil
        )
          @player_id = player_id
          @opposing_player_id = opposing_player_id
          @extra_player_id = extra_player_id
          @team_id = team_id
          @type = type
          @foul_type = foul_type
          @index = index
          @loc_x = loc_x
          @loc_y = loc_y
          @seconds_remaining = seconds_remaining
          @three = three
        end

        def shot?
          @type.in? %i[made_shot missed_shot]
        end

        def three?
          shot? ? @three : false
        end

        def technical?
          @type == :foul && @foul_type == :technical
        end

        def could_be_a_coach?
          technical? || @type == :ejection
        end
      end
    end
  end
end
