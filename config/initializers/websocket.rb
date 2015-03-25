EM.run do
  EM::WebSocket.start(:host => '0.0.0.0', :port => '3030') do |ws|
    clients = []

    crypt = ActiveSupport::MessageEncryptor.new(ENV['SECRET_KEY_BASE'])
    p crypt
    ws.onopen do |handshake|
      conversation_data = crypt.decrypt_and_verify(handshake.query_string)
      clients << {socket: ws, conv_info: conversation_data}
      ws.send Conversation.find(conversation_data[:conversation_id]).messages.last(10).to_json
    end

    ws.onclose do
      ws.send "Closed."
      clients.delete ws
    end

    ws.onmessage do |data|
      data = data.split('L56HTY9999')
      body = data[0]
      key = data[-1]
      conversation = crypt.decrypt_and_verify(key)
      new_message = Message.new(body: body, user_id: conversation[:user_id], conversation_id: conversation[:conversation_id])
      if new_message.save
        clients.each do |socket|
          if socket[:conv_info][:conversation_id] == conversation[:conversation_id]
            socket[:socket].send new_message.to_json
          end
        end
      else
        if socket[:conv_info][:user_id] == conversation[:user_id]
          socket[:socket].send new_message.errors.to_json
        end
      end
    end
  end
end
