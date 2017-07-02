# This is a set of relatively basic helpers that could be used lots of places
# in the scraper.
module Scraper
  module Utility
    def self.correct_player_id(id)
      id = to_i_or_nil(id)
      # There's at least one known example of a broken player ID that's really
      # a duplicate of another. I'm guessing there will be more of these.
      known_dupes = {
        1_628_244 => 202_288
      }
      known_dupes.key?(id) ? known_dupes[id] : id
    end

    def self.to_i_or_nil(str_or_i, allow_zero: false)
      like_nil = (allow_zero ? ['', nil] : ['', nil, 0]).include? str_or_i
      like_nil ? nil : str_or_i.to_i
    end

    def self.wait_a_sec
      sleep rand(1..3)
    end
  end
end
