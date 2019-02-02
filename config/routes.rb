Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  scope '/api' do
    post '/register' => 'api#register'
    get '/commonstudents' => 'api#common_students'
    post '/suspend' => 'api#suspend'
    post '/retrievefornotifications' => 'api#retrievefornotifications'
  end
end
