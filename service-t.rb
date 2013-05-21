#$LOAD_PATH  << './lib'
require 'rubygems'
require 'bundler/setup'
require "sinatra/base"
require 'active_record'
require 'YAML'
require "branch_service"

class Service < Sinatra::Base


configure do
    puts "STARTING"
    env =  "development"
    databases = YAML.load_file("../project/gutrees/config/database.yml")
    ActiveRecord::Base.establish_connection(databases[env])
    @service= BranchService.instance
    @service.start
  end

post '/api/v1/create_group' do
  begin
    data =JSON.parse(request.body.read)
    group_name= data[:group][:name]
    group_owner=data[:group][:owner]
  rescue => e
  end
end

post '/api/chat/v1/add_admin' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

post '/api/chat/v1/add_admin' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

post '/api/chat/v1/remove_admin' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

post '/api/chat/v1/add_member' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

post '/api/chat/v1/remove_member' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

post '/api/chat/v1/ban_member' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

post '/api/chat/v1/remove_admin' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end
delete '/api/chat/v1/destroy_group' do
  begin
    data =JSON.parse(request.body.read)
    admins= data[:group][:admin]
  rescue => e
  end
end

at_exit do
  puts "SHUTTING DOWN"
  @service.stop
end
# $0 is the executed file
# __FILE__ is the current file
run! if __FILE__ == $0

end

