role :app, "54.153.18.9"
role :web, "54.153.18.9"
role :db,  "54.153.18.9", primary: true

set :branch, "master"
set :deploy_to, "/home/ubuntu/deployment.quantum"
set :deploy_via, :remote_cache
set :rails_env, "production"
