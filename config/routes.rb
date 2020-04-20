Rails.application.routes.draw do

  root :to => 'messages#index'

  resources :messages do
    member do
      post :prescription
    end
  end
end
