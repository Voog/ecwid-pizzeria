EcwidPizzeria::Application.routes.draw do
  root :to => 'payments#create'
  
  resources :payments
  
  match '/ipizza/callback/:provider(/:result)' => 'ipizza#callback'
end
