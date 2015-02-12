set :application, 'example_app_ecwid_pizzeria'

set :linked_files, fetch(:linked_files, []).push('config/application.yml', 'config/banks.yml')
# set :linked_files, fetch(:linked_files, []).push('config/application.yml', 'config/banks.yml', 'vendor/assets/stylesheets/custom/style.scss')
set :linked_dirs, fetch(:linked_dirs, []).push('config/certificates')
# set :linked_dirs, fetch(:linked_dirs, []).push('config/certificates', 'vendor/assets/images/custom')

namespace :deploy do
  desc 'Upload configuration and certificates'
  task :upload_configuration do
    on hosts do |host|
      local_conf_folder = "./custom/example_app"

      execute "mkdir -p #{shared_path}/config"
      %w(config/application.yml config/banks.yml config/database.yml).each do |f|
        upload! "#{local_conf_folder}/#{f}", "#{shared_path}/#{f}"
      end
      %w(config/certificates).each do |folder|
        upload! "#{local_conf_folder}/#{f}", "#{shared_path}/#{f}", recursive: true
      end
    end
  end

  after :publishing, :restart
end
