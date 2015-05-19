set :rbenv_type, :user
set :rbenv_ruby, '2.2.0'

# set :rvm_type, :user
# set :rvm_ruby_version, '2.2.0'

set :stage, :production
set :rails_env, 'production'
# set :deploy_to, '/var/www/my_app_name'

role :app, %w{example@example.com}
role :web, %w{example@example.com}
role :db,  %w{example@example.com}
