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


class Service < Sinatra::Base
  include TorqueBox::Injectors
  use TorqueBox::Session::ServletStore
  

 
  configure do
    puts "STARTING"
    ActiveRecord::ConnectionAdapters::ConnectionManagement
    databases = YAML.load_file("config/database.yml")
    ActiveRecord::Base.establish_connection(databases[ENV['db']])
    require "models/interswitch_helper"
    require "models/airtime"
    require "models/order"
    require "models/user"
    require "models/wallet"
    require "models/purchase_order"
    require "models/money_order"
    $redis = Redis.new(:host => 'localhost', :port => 6379)
  end

  get "/foo"  do
    session[:message] ="Helloworld"
    redirect to("push")
  end

get '/push' do
  order=Order.includes([{:user=>:wallet},:item]).find_by_transaction_id(params[:transaction_id])
  if order
   @poploda_service = fetch( 'service:PoplodaService' )
   jid=$redis.hget("users:#{params[:phone_number]}","jid")
   @poploda_service.notify_transaction(jid,order)
  end
  session[:message]
end

post '/notify_transaction' do
    transaction = JSON.parse(request.body.read)
    puts "STARTING TRANSACTION : #{transaction}"
    order=Order.includes([{:user=>:wallet},:item]).find_by_transaction_id(transaction['transaction_id'])
    if order
     @poploda_service = fetch( 'service:PoplodaService' )
     jid=$redis.hget("users:#{transaction['phone_number']}","jid")
     @poploda_service.notify_transaction(jid,order)
    end
end

end

