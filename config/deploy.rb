require 'bundler/capistrano'

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/poploda"
#load "config/recipes/postgresql"
load "config/recipes/trinidad"

server "poploda.com", :web, :app, :db, primary: true

set :application, "poploda_service"
set :user, "deployer"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:evenmatrix/#{application}.git"
set :scm_username, "evenmatrix@gmail.com"
set :branch, "master"
set :git_enable_submodules, 1


default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:paranoid] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases


