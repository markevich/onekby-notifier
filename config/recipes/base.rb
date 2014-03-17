def template(from, to)
  erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  put ERB.new(erb).result(binding), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end

namespace :deploy do
  task :create_configs_symlink, :roles => :app do
    run "rm -Rf #{release_path}/log"

    run "ln -nfs #{shared_path}/log #{release_path}/log"
    run "ln -nfs #{shared_path}/sockets #{release_path}/tmp/sockets"
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/uploads"
  end
  after "deploy:create_symlink", "deploy:create_configs_symlink"

  task :link_yml do
    run "ln -s #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -s #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
  end

  before "deploy:assets:symlink", "deploy:link_yml"
end
