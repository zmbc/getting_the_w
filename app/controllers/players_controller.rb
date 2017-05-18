class PlayersController < ApplicationController
  def view
    @player = Player.find params[:id].to_i
    season = params[:season].blank? ? Time.now.year : params[:season].to_i
    gon.shot_chart_data = @player.shot_distribution_and_accuracy(season)
  end
end
