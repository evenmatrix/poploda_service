$LOAD_PATH  << './lib'
require "singleton"
require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'logger'
require 'yaml'

['xpp3','stringprep','dom4j','whack','slf4j-api','slf4j-log4j12','log4j'].each do |name|
  require "#{name}.jar"
end

require_relative 'poploda_notifications'

include Java
import org.jivesoftware.whack.ExternalComponentManager
import org.xmpp.component.ComponentException

class PoplodaService
  include Singleton


   def initialize()
    opts =YAML.load_file("config/poploda.yml")
    set_up_logger(opts["log_path"])
    @logger.info "INITIALIZING"
    @host=opts["server_host"]
    @port=opts["server_port"]
    @sub_domain=opts["sub_domain"]
    @secret=opts["secret"] 
    @env = opts["env"] 
    @component = PoplodaNotificationsComponent.new @sub_domain,@host,opts
    @manager = ExternalComponentManager.new @host,@port;
    @manager.setSecretKey(@sub_domain,@secret);
    @manager.setMultipleAllowed(@sub_domain, true);
    @logger.info "#{@host} #{@port} #{@sub_domain} #{@env}"
  end

  def start
    begin
    puts "START"
    @manager.addComponent @sub_domain,@component
    rescue ComponentException => e
    @logger.error e
    end
  end

  def stop
    begin
    @manager.removeComponent @sub_domain
    puts "STOP"
    rescue ComponentException=>e
      @logger.error e
    end
  end

  def push(data)
    @logger.info "pushed #{data}"
    
  end
  
  def notify_transaction(phone_number,order)
   @component.notify_transaction(phone_number,order)
  end

  def notify_json(phone_number,json)
   @component.notify_json(phone_number,json)
  end
  
  def set_up_logger(log_path)
    path = File.join(log_path, 'poploda.log')
    file = File.open(path, File::WRONLY | File::APPEND | File::CREAT)
    file.sync = true
    @logger = Logger.new(file)
    @logger.level = Logger::DEBUG
  end


end