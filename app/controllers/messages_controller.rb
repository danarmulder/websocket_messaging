class MessagesController < ApplicationController
  before_action do
    @conversation = Conversation.find(params[:conversation_id])
  end

  @clients = []


  EM::WebSocket.start(:host => '0.0.0.0', :port => '3001') do |ws|
    ws.onopen do |handshake|
      @clients << ws
      ws.send "Connected to #{handshake.path}."
    end

    ws.onclose do
      ws.send "Closed."
      @clients.delete ws
    end

    ws.onmessage do |data|
      crypt = ActiveSupport::MessageEncryptor.new(ENV['SECRET_KEY_BASE'])
      data = data.split('L56HTY9999')
      body = data[0]
      key = data[-1]
      conversation = crypt.decrypt_and_verify(key)
      @clients.each do |socket|
        socket.send body
        p socket
      end
      Message.new(body: body, user_id: conversation[:user], conversation_id: conversation[:conversation]).save
    end

  end

  def index
    crypt = ActiveSupport::MessageEncryptor.new(ENV['SECRET_KEY_BASE'])
    @conv_id = crypt.encrypt_and_sign({:user=>current_user.id,:conversation=>@conversation.id})
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
