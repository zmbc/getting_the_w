Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/players/:id', to: 'players#view'
  get '/api/players/shot_chart_data', to: 'players#shot_chart_data'
end
