require "bundler/capistrano"
require 'rvm/capistrano'

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

load 'config/recipes/base'
load 'config/recipes/nginx'
load 'config/recipes/unicorn'
load 'config/recipes/sidekiq'
load 'config/recipes/monit'

set :application, "onekby-notifier"
set :deploy_to, "/home/onek-bot/#{application}"

set :branch, 'master'
set :repository,  "git@github.com:markevich/onekby-notifier.git"
set :deploy_via, :remote_cache
set :copy_exclude, [ '.git' ]


set :rvm_ruby_version, "2.1.2"
set :rvm_type, :system

server "192.241.209.135", :app, :web, :db, primary: true

set :user, 'onek-bot'
set :use_sudo, false

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after 'deploy', 'deploy:cleanup'
