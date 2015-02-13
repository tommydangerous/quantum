require "mina/bundler"
require "mina/rails"
require "mina/git"
require "mina/rvm"
require "mina/unicorn"

set :rails_env,  "production"
set :domain,     "quantum"
set :deploy_to,  "/var/www/quantum"
set :repository, "https://github.com/tommydangerous/quantum.git"
set :branch,     "master"

# Manually create these paths in shared/ (eg: shared/config/database.yml)
# in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ["config/database.yml", "config/secrets.yml", "log", ".env"]

set :user, "ubuntu"
set :ssh_options, "-A"
# set :port, 22

task :environment do
  invoke :"rvm:use[2.2.0]"
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue  %[echo "-----> Be sure to edit 'shared/config/database.yml'."]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :"git:clone"
    invoke :"deploy:link_shared_paths"
    invoke :"bundle:install"
    invoke :"rails:db_migrate"
    # invoke :"rails:assets_precompile"

    to :launch do
      invoke :"unicorn:start"
    end
  end
end
