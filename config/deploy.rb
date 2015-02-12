require "bundler/capistrano"
require "capistrano/ext/multistage"
require "dotenv/deployment/capistrano"
require "rvm/capistrano"

set :application, "quantum"

# Ensure any needed password prompts from SSH show up in your terminal
default_run_options[:pty] = true

set :repository, "git@github.com:tommydangerous/quantum.git"
set :scm, :git

set :user, "ubuntu"
set :use_sudo, false

set :stages, %w(staging production)
set :default_stage, "staging"

set :format, :pretty

ssh_options[:forward_agent] = true
ssh_options[:keys] = ["~/.ssh/aws_west_1.pem"]

set :keep_releases, 5

# Directory symlink
set :webroot, "/home/ubuntu/quantum"

# After running the 1st deploy, make some shared directories and a symlink
after "deploy:setup", "deploy:init_shared"
after "deploy:setup", "deploy:symlink_webroot"

# After a code update, symlink shared files into the new release
after "deploy:update_code", "deploy:symlink_shared"
after "deploy:update_code", "deploy:migrate"

after "deploy:restart", "deploy:cleanup"

load "deploy/assets"

namespace :deploy do
  task :init_shared do
    run "mkdir -p #{shared_path}/config"
    run "mkdir -p #{shared_path}/db"
    run "mkdir -p #{shared_path}/log"
  end

  task :symlink_webroot do
    run "ln -sf #{deploy_to}/current #{webroot}"
  end

  task :symlink_shared do
    # Files that we need to symlink into the new release
    files = [

    ]
    files.each do |path|
      run "touch #{shared_path}/#{path}"
      run "ln -sf #{shared_path}/#{path} #{release_path}/#{path}"
    end
  end
end
