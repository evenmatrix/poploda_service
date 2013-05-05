$LOAD_PATH  << '../lib'
#require "singleton"
require 'rubygems'
require 'active_record'
require 'bundler/setup'
require 'yaml'
require 'logger'

['xpp3','stringprep','dom4j','whack','slf4j-api','slf4j-log4j12','log4j'].each do |name|
  require "#{name}.jar"
end

require_relative '../poploda_notifications'

include Java
import org.jivesoftware.whack.ExternalComponentManager
import org.xmpp.component.ComponentException

class PoplodaService
  attr_reader   :host,:port
  NS_NOTIFICATION = 'http://poploda.com/notifications'
  
  def initialize(opts={})
    puts "INITIALIZING"
    @host=opts["server_host"]||'rzaartz.local'
    @port=opts["server_port"]||8888
    @sub_domain=opts["sub_domain"]|| 'poploda'
    @secret=opts["secret"] || 'secret'
    @env = opts["env"] || "development"
    @component = PoplodaNotificationsComponent.new @sub_domain,@host,opts
    @manager = ExternalComponentManager.new @host,@port;
    @manager.setSecretKey(@sub_domain,@secret);
    @manager.setMultipleAllowed(@sub_domain, true);
    set_up_logger(opts["log_path"])
    @logger.info "#{@host} #{@port} #{@sub_domain} #{@env}"
  end

  def start
    begin
    @manager.addComponent @sub_domain,@component
    rescue ComponentException => e
    puts e
    end
  end

  def stop
    begin
    @manager.removeComponent @sub_domain
    rescue ComponentException=>e
      puts e
    end
  end

  def push(data)
    @logger.info "pushed #{data}"
    
  end
  
  def notify_transaction(phone_number,order)
   @component.notify_transaction(phone_number,order)
  end

  def set_up_logger(log_path)
    if @env == "development"
      @logger = TorqueBox::Logger.new( self.class )
    end 
    if @env == "production"
      path = File.join(log_path, 'branch.log')
      file = File.open(path, File::WRONLY | File::APPEND | File::CREAT)
      file.sync = true
      @logger = Logger.new(file)
      @logger.level = Logger::DEBUG
    end
  end


end