require 'net/http'
require 'json'

namespace :scrape do
  desc 'Scrape a season'
  task :season, [:year] => :environment do |_, args|
    Scraper.scrape_season(args[:year].to_i)
  end

  desc 'Scrape the current (calendar year) season'
  task current_season: :environment do
    current_season = Time.zone.now.year
    Scraper.scrape_season(current_season)
  end

  desc 'Scrape the last X days'
  task :last_x_days, [:x] => :environment do |_, args|
    now = Time.zone.now
    start = now - args[:x].to_i.days
    Scraper.scrape_since(start)
  end

  desc 'Scrape the last day'
  task last_day: :environment do
    now = Time.zone.now
    one_day_ago = now - 1.day
    Scraper.scrape_since(one_day_ago)
  end

  task remove_unnecessary_players: :environment do
    Player.remove_unnecessary!
  end
end
