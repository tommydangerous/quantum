require "mina/bundler"
require "mina/rails"
require "mina/git"
require "mina/rvm"

#                                                                         Config
# ==============================================================================
set :rails_env,  "production"

set :domain,     "quantum"

set :deploy_to,  "/var/www/quantum"
set :app_dir,    "#{deploy_to}/current"
set :shared_dir, "#{deploy_to}/shared"

set :repository, "https://github.com/tommydangerous/quantum.git"
set :branch,     "master"

set :user,       "ubuntu"
# Manually create these paths in shared/ (eg: shared/config/database.yml)
# in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, %w{.env log config/database.yml config/secrets.yml}
set :keep_releases, 5

set :ssh_options, "-A"
# set :port, 22

#                                                                            RVM
# ==============================================================================
task :environment do
  invoke :"rvm:use[2.2.0]"
end

#                                                                     Setup task
# ==============================================================================
# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  %w{config log pids sockets}.each do |folder|
    queue! %[mkdir -p "#{shared_dir}/#{folder}"]
    queue! %[chmod g+rx,u+rwx "#{shared_dir}/#{folder}"]
  end

  %w{.env config/database.yml config/secrets.yml}.each do |file|
    queue! %[touch "#{shared_dir}/#{file}"]
    queue  %[echo "-----> Be sure to edit 'shared/#{file}'."]
  end
end

#                                                                    Deploy task
# ==============================================================================
desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :"git:clone"
    invoke :"deploy:link_shared_paths"
    invoke :"bundle:install"
    invoke :"rails:db_migrate"
    invoke :"rails:assets_precompile"

    to :launch do
      invoke :"unicorn:restart"
    end
  end
end

#                                                                        Unicorn
# ==============================================================================
namespace :unicorn do
  set :unicorn_pid, "#{shared_dir}/pids/unicorn.pid"
  set :start_unicorn, %{
    cd #{app_dir}
    bundle exec unicorn -c #{app_dir}/config/unicorn.rb -E #{rails_env} -D
  }

#                                                                     Start task
# ------------------------------------------------------------------------------
  desc "Start unicorn"
  task :start => :environment do
    queue "echo \"-----> Start Unicorn\""
    queue! start_unicorn
  end

#                                                                      Stop task
# ------------------------------------------------------------------------------
  desc "Stop unicorn"
  task :stop do
    queue "echo \"-----> Stop Unicorn\""
    queue! %{
      test -s "#{unicorn_pid}" && kill -QUIT `cat "#{unicorn_pid}"` && echo "Stop OK" && exit 0
      echo >&2 "Not running"
    }
  end

#                                                                   Restart task
# ------------------------------------------------------------------------------
  desc "Restart unicorn using 'upgrade'"
  task :restart => :environment do
    invoke "unicorn:stop"
    invoke "unicorn:start"
  end
end
