require 'rubygems'
require 'active_record'
require 'action_view'
require 'redis'
require 'json'
include Java
import org.xmpp.component.AbstractComponent
import org.xmpp.packet.IQ
import org.xmpp.packet.JID
import org.xmpp.packet.Presence
import org.xmpp.packet.Message
import org.xmpp.packet.PacketError::Condition
import org.xmpp.component.ComponentException
import org.dom4j.Element;

require "#{File.dirname(__FILE__)}/models/response_messages"
require "#{File.dirname(__FILE__)}/models/orders_helper"

class  PoplodaNotificationsComponent <  AbstractComponent
  include OrdersHelper
  NS_NOTIFICATIONS = "http://poploda.com/notifications"
  #NS_NOTIFICATION_ITEM = "http://poploda.com/notifications/item"

  
  def initialize(name=nil,server_domain=nil,opts={})
    super(false)
    @name=name
    @server_domain=server_domain
    @domain=opts["domain"]
    @jid=nil
    @env=opts["env"] || "development"
    @component_manager=nil
    @last_start_millis=nil
    @redis =Redis.new(:host => 'localhost', :port => 6379)
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
  
  def notify_transaction(jid,order)
    begin
    message=create_notificaion_message_from_order(order)
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
  end

  def handle_group_chat_message(message)

  end

  def send_notification(jid,message)
    #jid=@redis.hget("users:#{phone_number}","jid")
    if(!jid.nil?)
      from_jid= JID.new(@domain)
      message.to=JID.new(jid)
      message.from=from_jid
      @logger.info "sending:#{message.to_xml}"
      send(message)
    end
  end
  
  def create_notificaion_message_from_order(order)
     message=Message.new
     add_message_attributes_for_transaction(order,message)
     date = message.add_child_element("date",NS_NOTIFICATIONS);
     date.setText(order.created_at.to_time.to_i.to_s);
     formatted_date = message.add_child_element("formatted-date",NS_NOTIFICATIONS);
     date_format="#{order.created_at.strftime('%a %d %b %Y')} #{order.created_at.strftime("%I:%M%p")}"
     formatted_date.setText(date_format);
     return message
   end
   
   def add_message_attributes_for_transaction(order,message)
      elem = message.add_child_element("notification",NS_NOTIFICATIONS);
      elem.add_attribute "type","transaction"
      item=elem.add_element("item");
      item.add_attribute "transaction-id",order.transaction_id.to_s
      item.add_attribute "item-type",order.item_type
      item.add_attribute "name",order.name
      item.add_attribute "payment-method",order.payment_method
      item.add_attribute "amount",order.amount.to_s
      item.add_attribute "amount-currency","NGN #{order.amount.to_i.to_s}"
      item.add_attribute "state",order.state
      item.add_attribute "date",order.created_at.to_time.to_i.to_s
      item.add_attribute "response-description",order.response_description
      item.add_attribute "response-code",order.response_code
      if order.success?
        case order.item_type
           when "Wallet"
              status=order_status(order,{:message=>"Your Wallet Has Been Credited",:description=>"NGN #{order.amount.to_i.to_s} has been credited to your wallet"})
              message.set_subject status[:message]
              message.set_body status[:description]
              wallet=item.add_element("wallet");
              add_wallet_attributes(wallet,order)
          when "Airtime"
              status=order_status(order,{:message=>"#{order.item.name.upcase} recharge successful",:description=>"your pin is #{order.item.pin}.Thank you! "})
              message.set_subject status[:message]
              message.set_body status[:description]
              airtime=item.add_element("airtime");
              airtime.add_attribute "pin",order.item.pin
              airtime.add_attribute "dial",order.item.one_click.to_s
              if(order.payment_method=="wallet")
                wallet=item.add_element("wallet");
                add_wallet_attributes(wallet,order)
              end
       end
     else  
           message.set_subject "Transaction Failed"
           message.set_body order.response_description
     end
   end

   def add_wallet_attributes(wallet,order)
     wallet.add_attribute "account-balance",order.item.account_balance.to_s
     wallet.add_attribute "account-balance-currency","NGN #{order.amount.to_i.to_s}"
     wallet.add_attribute "touch",order.item.updated_at.to_time.to_i.to_s
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
      puts "Error :,#{e.message}"
      puts $!.backtrace.collect { |b| " > #{b}" }.join("\n")
    ensure
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
    jid=@redis.hget("users:#{phone_number}","jid")
    if(jid == presence.from.to_s)
      @redis.del("users:#{phone_number}")
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
    @redis.hset("users:#{phone_number}","jid",from.to_s)
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
    if @env == "development"
      @logger = TorqueBox::Logger.new( self.class )
    end 
    if @env == "production"
      path = File.join(log_path, 'poploda.log')
      file = File.open(path, File::WRONLY | File::APPEND | File::CREAT)
      file.sync = true
      @logger = Logger.new(file)
      @logger.level = Logger::DEBUG
    end
  end
  
  def close_connection
  end
end