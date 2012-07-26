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

server 'dev.protein', :app, :web, :db, :primary => true

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
