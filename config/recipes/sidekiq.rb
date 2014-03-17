set_default(:sidekiq_pid) { "#{shared_path}/pids/sidekiq.pid" }
set_default(:sidekiq_config) { "#{shared_path}/config/sidekiq.rb" }
set_default(:sidekiq_log) { "#{shared_path}/log/sidekiq.log" }

namespace :sidekiq do

  desc "Setup Sidekiq initializer and app configuration"
  task :setup, roles: :app do

    template "sidekiq_init.erb", "/tmp/sidekiq_init"
    run "chmod +x /tmp/sidekiq_init"
    run "#{sudo} mv /tmp/sidekiq_init /etc/init.d/sidekiq_#{application}"
    run "#{sudo} update-rc.d -f sidekiq_#{application} defaults"

    run "service sidekiq_#{application} restart"
  end
  after "deploy:setup", "sidekiq:setup"

  %w[start stop restart].each do |command|
    desc "#{command} sidekiq"
    task command, roles: :app do
      run "service sidekiq_#{application} #{command}"
    end
    after "deploy:#{command}", "sidekiq:#{command}"
  end
end
