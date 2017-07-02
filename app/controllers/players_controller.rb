class PlayersController < ApplicationController
  def search
    if params[:q]
      @q = params[:q]
      @players = Player

      @q.split(' ').each do |word|
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
  end

  def shot_chart_data
    @player = Player.find params[:id].to_i
    season = params[:season].to_i
    render json: @player.shot_distribution_and_accuracy(season)
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
