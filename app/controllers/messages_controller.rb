class MessagesController < ApplicationController
  before_action do
    @conversation = Conversation.find(params[:conversation_id])
  end
  @clients = []
  EM.run do
    EM::WebSocket.start(host: ENV['WEBSOCKET_HOST'], port: ENV['WEBSOCKET_PORT']) do |ws|
      crypt = ActiveSupport::MessageEncryptor.new(ENV['SECRET_KEY_BASE'])
      p crypt
      ws.onopen do |handshake|
        conversation_data = crypt.decrypt_and_verify(handshake.query_string)
        @clients << {socket: ws, conv_info: conversation_data}
        ws.send Conversation.find(conversation_data[:conversation_id]).messages.last(10).to_json
      end

      ws.onclose do
        ws.send "Closed."
        @clients.delete ws
      end

      ws.onmessage do |data|
        data = data.split('L56HTY9999')
        body = data[0]
        key = data[-1]
        conversation = crypt.decrypt_and_verify(key)
        new_message = Message.new(body: body, user_id: conversation[:user_id], conversation_id: conversation[:conversation_id])
        if new_message.save
          @clients.each do |socket|
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


  def index
    crypt = ActiveSupport::MessageEncryptor.new(ENV['SECRET_KEY_BASE'])
    @conv_id = crypt.encrypt_and_sign({:user_id=>current_user.id,:conversation_id=>@conversation.id})
    @conversation.recipient.id
    @conversation.sender.id
    @messages = @conversation.messages
    if @messages.length > 10
      @over_ten = true
      @messages = @messages[-10..-1]
    end
    if params[:m]
      @over_ten = false
      @messages = @conversation.messages
    end
    if @messages.last
      if @messages.last.user_id != current_user.id
        @messages.last.read = true;
      end
    end

    @message = @conversation.messages.new
  end

  def new
    @message = @conversation.messages.new
  end

  def create(body)
    @message = @conversation.messages.new(body: body, user_id: current_user.id)
    if @message.save
    end
  end

private
  def message_params
    params.require(:message).permit(:body, :user_id)
  end
end
