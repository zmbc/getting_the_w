class PlayersController < ApplicationController
  def search
    if params[:q]
      @q = params[:q]
      @players = Player

      @q.split(' ').each do |word|
        # Three players in the WNBA have spaces in their last names, which
        # throws a bit of a wrench into this simple word-based strategy. For
        # now, I'm just ignoring the second words of their last names:
        # - Elena Delle Donne
        # - Amanda Zahui B
        # - Erika de Souza
        next if word.downcase.in? ['donne', 'b', 'souza']
        @players = @players.where('first_name like :query or last_name like :query',
                                query: "#{word}%")
      end
    else
      @players = []
      @q = nil
    end
  end

  def view
    @player = Player.find params[:id].to_i
    first_year = Game.includes(:shots)
                     .where(shots: {player_id: @player.id})
                     .minimum(:date).year
    last_year = Game.includes(:shots)
                     .where(shots: {player_id: @player.id})
                     .maximum(:date).year
    @years = first_year..last_year
    gon.player_id = @player.id
    @season = params[:season].blank? ? Time.now.year : params[:season].to_i
    gon.season = @season
    @summary_stats = @player.summary_stats(@season)
  end

  def shot_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.shot_distribution_and_accuracy(season)
  end

  def distance_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.distance_distribution_and_accuracy(season)
  end

  def game_time_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.game_time_distribution_and_accuracy(season)
  end

  def over_season_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.over_season_distribution_and_accuracy(season)
  end

  def team_effect_shot_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.team_shot_deltas_distribution(season)
  end

  def opposing_team_effect_shot_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.opposing_team_shot_deltas_distribution(season)
  end
end
