set_default(:server_host, "poploda.com")
set_default(:server_port, "8888")
set_default(:sub_domain, "push")
set_default(:secret, "secret")
set_default(:env, "production")

namespace :poploda do
  desc "Generate torquebox.yml file."
  task :setup, roles: :app do
    run "mkdir -p #{shared_path}/config"
    template "torquebox.yml.erb", "#{shared_path}/config/torquebox.yml"
  end
  after "deploy:setup", "poploda:setup"
  
  desc "Symlink the torquebox.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/torquebox.yml #{release_path}/config/torquebox.yml"
  end
  after "deploy:finalize_update", "poploda:symlink"
  
end