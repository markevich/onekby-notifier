namespace :nginx do
  desc "Setup nginx configuration for this application"
  task :setup, roles: :web do
    template "nginx.erb", "/tmp/nginx_conf"
    run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
    run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
    run "#{sudo} service nginx reload"
  end
  after "deploy:setup", "nginx:setup"

  %w[start stop restart reload configtest].each do |command|
    desc "#{command} nginx"
    task command, roles: :web do
      run "#{sudo} service nginx #{command}"
    end
  end
end
