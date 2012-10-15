PayaloguePlusApiExample::Application.routes.draw do
  root :to => "home#index"
  match "report" => "purchases#report"
  resources :products, :only => :index do
    resources :purchases, :only => [:new, :create]
  end
end
