namespace :monit do
  desc "Setup monit configuration for this application"
  task :setup, roles: [:app, :web] do
    template "monit_unicorn.erb", "/tmp/monit_unicorn_conf"
    template "monit_sidekiq.erb", "/tmp/monit_sidekiq_conf"

    run "#{sudo} mv /tmp/monit_unicorn_conf /etc/monit/conf.d/#{application}_unicorn"
    run "#{sudo} mv /tmp/monit_sidekiq_conf /etc/monit/conf.d/#{application}_sidekiq"

    run "#{sudo} service monit restart"
  end
  after 'deploy:setup', 'monit:setup'
end
