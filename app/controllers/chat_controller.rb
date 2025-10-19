class ChatController < ApplicationController
  # before_action :authenticate_user!

  def index
    @conversation = current_user.current_conversation
    @messages = @conversation.messages.order(:created_at)
  end

  def message
    conversation = current_user.current_conversation
    user_message = params[:message]

    conversation.add_message('user', user_message)

    # Process with AI agent
    response = AiAgentService.new(current_user, conversation).process(user_message)

    conversation.add_message('assistant', response[:content], response[:metadata])

    render json: {
      content: response[:content],
      metadata: response[:metadata]
    }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def history
    conversation = current_user.current_conversation
    messages = conversation.messages.order(:created_at).map do |msg|
      {
        role: msg.role,
        content: msg.content,
        metadata: msg.metadata,
        created_at: msg.created_at
      }
    end
    render json: { messages: messages }
  end
end
