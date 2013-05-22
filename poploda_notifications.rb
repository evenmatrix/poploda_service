require 'rubygems'
require 'active_record'
require 'json'
require 'logger'
include Java
import org.xmpp.component.AbstractComponent
import org.xmpp.packet.IQ
import org.xmpp.packet.JID
import org.xmpp.packet.Presence
import org.xmpp.packet.Message
import org.xmpp.packet.PacketError::Condition
import org.xmpp.component.ComponentException
import org.dom4j.Element;

require "#{File.dirname(__FILE__)}/models/active_user"

class  PoplodaNotificationsComponent <  AbstractComponent
  NS_NOTIFICATIONS = "http://poploda.com/notifications"
  #NS_NOTIFICATION_ITEM = "http://poploda.com/notifications/item"

  
  def initialize(name=nil,server_domain=nil,opts={})
    super(false)
    @name=name
    @server_domain=server_domain
    @domain=opts["domain"]
    @jid=nil
    @env=opts["env"] || "development"
    ActiveRecord::ConnectionAdapters::ConnectionManagement
    databases = YAML.load_file("config/database.yml")
    ActiveRecord::Base.establish_connection(databases[@env])
    @component_manager=nil
    @last_start_millis=nil
    #@redis =Redis.new(:host => 'localhost', :port => 6379)
    set_up_logger(opts["log_path"])
  end

  def init(jid,component_manager)
    @jid=jid
    @component_manager=component_manager
    puts "inited #{@component_manager}"
  end

  def getName
    @name
  end

  def getDomain
    @domain
  end
  


  def notify_json(jid,json)
    begin
     message=Message.new
     item = message.add_child_element("json",NS_NOTIFICATIONS);
     item.setText(json);
    send_notification(jid,message)
    rescue Exception => e
      @logger.error "Error :,#{e.message}"
    end
  end 

  protected

  def handleMessage (message)
    begin
      if (message.type == Message::Type::chat)
        handle_chat_message(message)
      elsif(message.type == Message::Type::error)
        handle_error_message(message)
      elsif(message.type == Message::Type::group)
        handle_group_chat_message(message)
      else

      end
    rescue Exception => e
      @logger.error "Error :,#{e.message}"
    ensure
      close_connection
    end
  end

  def handle_chat_message(message)
  end

  def handle_error_message(message)
    puts "ERROR MESSAGE #{message.to_xml}"
  end

  def handle_group_chat_message(message)

  end

  def send_notification(jid,message)
    if(!jid.nil?)
      from_jid= JID.new(@domain)
      message.to=JID.new(jid)
      message.from=from_jid
      puts "sending:#{message.to_xml}"
      send(message)
    end
  end

   
  def handlePresence(presence)
    begin
      if (presence.type == Presence::Type::unavailable)
        handle_unavailable_presence(presence)
      elsif(presence.type == Presence::Type::error)
        handle_presence_error(presence)
      else
        available_presence(presence)
      end
    rescue Exception => e
      @logger.error "Error :,#{e.message}"
    ensure
      close_connection
    end
  end

  def handleIQResult(iq)
    puts "IQ result"
  end

  def handleIQError(iq)
  end

  def handleIQGet(iq)

  end

  def handleIQSet(iq)

  end

  def handle_unavailable_presence(presence)
    puts "to #{presence.to}"
    puts "from:#{presence.from}"
    puts "presence_type:#{presence.type}"
    to = presence.to;
    from=  presence.from
    phone_number = to.node
    puts "unavailable #{presence.from}"
    #jid=@redis.hget("users:#{phone_number}","jid")
    active_user=ActiveUser.find_by_phone_number(phone_number)
    if active_user && active_user.jid==presence.from.to_s
      active_user.destroy
    end
  end

  def available_presence(presence)
    puts "to #{presence.to}"
    puts "from:#{presence.from}"
    puts "presence_type:#{presence.type}"
    to = presence.to;
    from=  presence.from
    phone_number= to.node;
    puts "available #{presence.from}"
    active_user=ActiveUser.find_by_phone_number(phone_number)
    if active_user
      active_user.jid=from.to_s
      active_user.save
    else
      active_user=ActiveUser.create({:jid=>from.to_s,:phone_number=>phone_number})
    end
    message=Message.new
    message.setBody("we got ur presence")
    message.from=to
    message.to=from
    puts "sending #{message.to_xml}"
    send message
  end

  def handle_presence_error(presence)
  end
  
  def notify
  end
  
  def send(packet)
    begin
      @component_manager.send_packet(self, packet);
    rescue ComponentException => e
      puts "Error :,#{e.message}"
      puts $!.backtrace.collect { |b| " > #{b}" }.join("\n")
    end

  end

  
  def set_up_logger(log_path)
      path = File.join(log_path, 'poploda.log')
      file = File.open(path, File::WRONLY | File::APPEND | File::CREAT)
      file.sync = true
      @logger = Logger.new(file)
      @logger.level = Logger::DEBUG
  end

  def close_connection
    ActiveRecord::Base.connection.close
  end
end