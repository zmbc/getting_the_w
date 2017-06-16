class PlayersController < ApplicationController
  def view
    @player = Player.find params[:id].to_i
    gon.player_id = @player.id
    gon.season = params[:season].blank? ? Time.now.year : params[:season].to_i
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
