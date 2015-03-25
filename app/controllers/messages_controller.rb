class MessagesController < ApplicationController
  before_action do
    @conversation = Conversation.find(params[:conversation_id])
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
