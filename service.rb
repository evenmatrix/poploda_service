#$LOAD_PATH  << './lib'
require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'torquebox'
require 'redis'
require 'active_record'
require 'attr_encrypted'
require 'state_machine'
require 'yaml'
require "#{File.dirname(__FILE__)}/models/active_user"


class Service < Sinatra::Base
  include TorqueBox::Injectors
  use TorqueBox::Session::ServletStore
  

 
  configure do
    puts "STARTING"
    ActiveRecord::ConnectionAdapters::ConnectionManagement
    databases = YAML.load_file("config/database.yml")
    ActiveRecord::Base.establish_connection(databases[ENV['db']])
   end

  get "/foo"  do
    session[:message] ="Helloworld"
    redirect to("push")
  end



post '/notify' do
  json = JSON.parse(request.body.read)
  puts "STARTING NOTIFICATION : #{request.body.read}"
  @poploda_service = fetch( 'service:PoplodaService' )
  active_user=ActiveUser.find_by_phone_number(params[:phone_number])
  if active_user
    @poploda_service.notify_json(active_user.jid,json.to_json)
  end
end

end

