require "bundler/capistrano"
require 'capistrano-rbenv'

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

set :application, "onekby-notifier"
set :deploy_to, "/home/deployer/#{application}"

set :branch, 'master'
set :repository,  "git@github.com:markevich/onekby-notifier.git"
set :deploy_via, :remote_cache
set :copy_exclude, [ '.git' ]


set :rbenv_ruby_version, "2.1.0"

server "artoverflow.com", :app, :web, :db, primary: true

set :user, 'deployer'
set :use_sudo, false

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after 'deploy', 'deploy:cleanup'
