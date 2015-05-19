Rails.application.routes.draw do
  root to: 'payments#new'

  namespace :admin do
    resources :estcard_messages
    resources :payments
    resources :bank_messages
    resources :paypal_messages
    get :app_settings, to: 'admin#app_settings'
  end

  get 'admin', to: redirect('/admin/payments')

  resources :discounts, only: [:show]

  match '/payments(/:provider)', to: 'payments#create', via: [:post]
  match '/ipizza/callback/:provider(/:result)', to: 'ipizza#callback', via: [:get, :post]
  match '/estcard/callback', to: 'estcard#callback', via: [:get, :post]
  match '/paypal/callback', to: 'paypal#callback', via: [:get, :post]
end
