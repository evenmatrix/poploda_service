module OrdersHelper

def order_status(order,success_message=nil)
  if(order.success?)
  if success_message
    return {:style=>"success",:message=>success_message[:message],:description=>success_message[:description]}
  else
    return {:style=>"success",:message=>"Transaction Successful",:description=>"Your Transaction was successful, thank you."}
  end
  end
  if(order.failed?)
    if order.response_code
      if order.payment_method=="interswitch"
        return interswitch_transaction_error_message(order)
      elsif
        order.payment_method=="wallet"
        return wallet_transaction_error_message(order)
      else
        return {:style=>"error",:message=>"Transaction Error",:description=>"Unknown Transaction Error"}
      end
    end
  end
  if(order.pending?)
    return {:style=>"warning",:message=>"Transaction Pending",:description=>"Awaiting payment confirmation"}
  end
  if(order.processing?)
    return {:style=>"error",:message=>"Transaction Error",:description=>"Unknown Transaction Error"}
  end
end

  def order_nav(tab)
    return render :partial=>'orders/nav',locals: {current_tab: tab}
  end

def order_nav_tab(title, url, options = {})
  current_tab = options.delete(:current)
  options[:class] = (current_tab == title) ? 'active' : ''
  link= link_to url do
   content_tag(:div,"",class:"tape").concat("#{title}")
  end
  content_tag(:li,link,options)
  end


  def interswitch_transaction_error_message(order)
    if INTERSWITCH_RESPONSE_CODE_TO_MESSAGE[order.response_code]
      return {:style=>"error",:message=>INTERSWITCH_RESPONSE_CODE_TO_MESSAGE[order.response_code],:description=>order.response_description}
    else
      return {:style=>"error",:message=>"Transaction Error",:description=>order.response_description}
    end
  end

  def wallet_transaction_error_message(order)
    if WALLET_RESPONSE_CODE_TO_MESSAGE[order.response_code]
      return {:style=>"error",:message=>WALLET_RESPONSE_CODE_TO_MESSAGE[order.response_code],:description=>order.response_description}
    else
      return {:style=>"error",:message=>WALLET_RESPONSE_CODE_TO_MESSAGE[order.response_code],:description=>order.response_description}
    end
  end

  def order_details(order)
     if order.type=="MoneyOrder"
       render :partial=> 'money_orders/order_details'
     end
     if order.item_type=="PurchaseOrder"
       render :partial=> 'purchase_orders/order_details'
     end
  end

end
