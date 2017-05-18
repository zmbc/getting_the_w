class PlayersController < ApplicationController
  def view
    @player = Player.find params[:id]
  end

  def shot_chart_data
    player = Player.find params[:id]
    render json: player.shot_distribution_and_accuracy(params[:season].to_i)
  end
end
