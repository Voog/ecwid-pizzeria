Rails.application.routes.draw do
  root to: 'payments#new'

  namespace :admin do
    resources :estcard_messages
    resources :payments
    resources :bank_messages
    resources :paypal_messages
    resources :make_commerce_messages
    get :app_settings, to: 'admin#app_settings'
  end

  get 'admin', to: redirect('/admin/payments')

  resources :discounts, only: [:show]
  resources :utilities, only: [:ip] do
    collection do
      get :ip
    end
  end

  match '/payments(/:provider)', to: 'payments#create', via: [:post], as: :payments
  match '/ipizza/callback/:provider(/:result)', to: 'ipizza#callback', via: [:get, :post]
  match '/estcard/callback', to: 'estcard#callback', via: [:get, :post]
  match '/paypal/callback', to: 'paypal#callback', via: [:get, :post]
  match '/make_commerce/:action_kind', as: :make_commerce, to: 'make_commerce#callback', via: [:get, :post], constraints: {action_kind: /(notification|cancel|return)/}
end
