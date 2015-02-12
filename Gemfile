source 'https://rubygems.org'

gem 'rails', '4.2.0'
gem 'ipizza-rails', '~> 2.0.1'
gem 'will_paginate', '~> 3.0.7'

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'bootstrap-sass', '~> 3.3.3'
gem 'jquery-rails'

gem 'figaro', '~> 1.1.0'

gem 'pg', '~> 0.18.1', group: :postgre
gem 'mysql2', '~> 0.3.17', group: :mysql

group :development do
  gem 'capistrano', '~> 3.3.5', require: false
  gem 'capistrano-multiconfig', '~> 3.0.8', require: false
  gem 'capistrano-rvm'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'quiet_assets', '~> 1.1.0'
end

group :test do
  gem 'rspec-rails', '~> 3.2.0'
  gem 'factory_girl_rails', '~> 4.5.0'
end
