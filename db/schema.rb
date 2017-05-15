# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170514083927) do

  create_table "games", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "home_team_id"
    t.bigint "visiting_team_id"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["home_team_id"], name: "index_games_on_home_team_id"
    t.index ["visiting_team_id"], name: "index_games_on_visiting_team_id"
  end

  create_table "on_courts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "player_id"
    t.bigint "shot_id"
    t.boolean "offense"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_on_courts_on_player_id"
    t.index ["shot_id"], name: "index_on_courts_on_shot_id"
  end

  create_table "players", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "shots", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.boolean "made"
    t.integer "loc_x"
    t.integer "loc_y"
    t.integer "period"
    t.integer "seconds_remaining"
    t.bigint "player_id"
    t.bigint "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "game_id"
    t.integer "evt"
    t.boolean "three"
    t.index ["game_id", "evt"], name: "index_shots_on_game_id_and_evt", unique: true
    t.index ["game_id"], name: "index_shots_on_game_id"
    t.index ["player_id"], name: "index_shots_on_player_id"
    t.index ["team_id"], name: "index_shots_on_team_id"
  end

  create_table "teams", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "city"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "games", "teams", column: "home_team_id"
  add_foreign_key "games", "teams", column: "visiting_team_id"
  add_foreign_key "on_courts", "players"
  add_foreign_key "on_courts", "shots"
  add_foreign_key "players", "teams"
  add_foreign_key "shots", "games"
  add_foreign_key "shots", "players"
  add_foreign_key "shots", "teams"
end
