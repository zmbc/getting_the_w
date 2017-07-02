Rails.application.routes.draw do
  get '/', to: 'players#search'
  get '/players/:id', to: 'players#view'
  get '/players/:id/shot_chart_data/:season', to: 'players#shot_chart_data'
  get '/players/:id/team_effect_shot_chart_data/:season', to: 'players#team_effect_shot_chart_data'
  get '/players/:id/opposing_team_effect_shot_chart_data/:season', to: 'players#opposing_team_effect_shot_chart_data'
end
