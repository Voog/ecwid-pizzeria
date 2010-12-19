EcwidPizzeria::Application.routes.draw do
  root :to => 'payments#new'
  
  resources :payments
  
  match '/ipizza/callback/:provider(/:result)' => 'ipizza#callback'
end
