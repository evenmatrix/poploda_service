require 'torquebox-capistrano-support'
require 'bundler/capistrano'

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/poploda"
#load "config/recipes/postgresql"

server "poploda.com", :web, :app, :db, primary: true

# SCM
set :deployer, "deployer"
set :application,"poploda_service"
set :user, "root"
set :scm, "git"
set :repository, "git@github.com:evenmatrix/#{application}.git"
set :scm_verbose,       true
set :use_sudo,          false
set :branch, "master"



default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup"

