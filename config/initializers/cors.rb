EcwidPizzeria::Application.configure do
  config.middleware.insert_before 0, "Rack::Cors", debug: !Rails.env.production?, logger: (-> { Rails.logger }) do
    allow do
      origins '*'

      resource '*',
        headers: :any,
        methods: [:get, :post, :delete, :put, :options, :head],
        max_age: 0
    end
  end
end
