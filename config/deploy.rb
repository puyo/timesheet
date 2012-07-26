require 'capistrano_colors'
require 'bundler/capistrano'

default_run_options[:pty] = true

set :application, 'timesheet'
set :repository, 'git@dev.protein:timesheet.git'
set :scm, :git
set :deploy_to, '/Users/ci/timesheet'
set :user, 'ci'
set :deploy_via, :copy
set :use_sudo, :false
set :run_method, :run
set :bundle_flags, '--deployment'
set :bundle_cmd, '/Users/ci/.rvm/gems/ree-1.8.7-2012.02@global/bin/bundle'

server 'dev.protein', :app, :web, :db, :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

after "deploy:update_code", "deploy:pipeline_precompile"

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  task :pipeline_precompile do
    run "cd #{release_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  end
end

