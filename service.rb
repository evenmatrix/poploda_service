#$LOAD_PATH  << './lib'
require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'active_record'
require 'logger'
require 'yaml'
require "#{File.dirname(__FILE__)}/models/active_user"
require "#{File.dirname(__FILE__)}/poploda_service"


class Service < Sinatra::Base
  
  configure do
    puts "STARTING"
    ActiveRecord::ConnectionAdapters::ConnectionManagement
    databases = YAML.load_file(File.join(File.dirname(__FILE__), "config/database.yml"))
    poploda_config = YAML.load_file(File.join(File.dirname(__FILE__),"config/poploda.yml"))
    ActiveRecord::Base.establish_connection(databases[poploda_config['env']])
    @service= PoplodaService.instance
    @service.start
   end

  get "/foo"  do
    session[:message] ="Helloworld"
    redirect to("push")
  end



post '/notify' do
  json = JSON.parse(request.body.read)
  @poploda_service = fetch( 'service:PoplodaService' )
  active_user=ActiveUser.find_by_phone_number(params[:phone_number])
  if active_user
    puts "STARTING NOTIFICATION : #{json.to_json} ==> #{active_user.jid}"
    @poploda_service.notify_json(active_user.jid,json.to_json)
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

