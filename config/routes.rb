EcwidPizzeria::Application.routes.draw do
  root :to => 'payments#create'
  
  resources :payments
end
