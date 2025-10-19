class AiAgentService
  SYSTEM_PROMPT = <<~PROMPT
    You are an intelligent AI assistant for a financial advisor. You have access to:
    - Gmail emails (can read and send emails)
    - Google Calendar (can read and create events)
    - Hubspot CRM (can read and manage contacts and notes)

    Your role is to help the financial advisor manage their client relationships by:
    1. Answering questions about clients using data from emails and Hubspot
    2. Performing tasks like scheduling appointments, sending emails, and managing CRM
    3. Being proactive when events happen (new emails, calendar updates, etc.)

    IMPORTANT: You have tools available. Use them intelligently to accomplish tasks.
    - When you need information, search for it using the appropriate tool
    - When you need to take action, use the relevant tool
    - You can use multiple tools in sequence to accomplish complex tasks
    - If a task requires waiting (like sending an email and waiting for a response), explain what you've done and what you're waiting for

    Be conversational, helpful, and take initiative to complete tasks fully.
    Think step-by-step about what tools you need to accomplish the user's request.
  PROMPT

  def initialize(user, conversation = nil)
    @user = user
    @conversation = conversation || @user.main_conversation
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def process(user_input)
    # Get RAG context
    context = get_rag_context(user_input)

    # Get ongoing instructions
    instructions = @user.ongoing_instructions.active.pluck(:instruction).join("\n")

    # Build messages for OpenAI
    messages = build_messages(user_input, context, instructions)

    # Let the LLM decide what to do - may use tools or just respond
    response = call_llm_with_tools(messages)

    {
      content: response[:content],
      metadata: response[:metadata]
    }
  end

  private

  def call_llm_with_tools(messages, max_iterations: 5)
    iteration = 0
    accumulated_tool_results = []

    loop do
      iteration += 1
      break if iteration > max_iterations

      response = @client.chat(
        parameters: {
          model: 'gpt-4-turbo-preview',
          messages: messages,
          tools: ToolRegistry.all_tools,
          tool_choice: 'auto',
          temperature: 0.7
        }
      )

      message = response.dig('choices', 0, 'message')

      # If no tool calls, we're done
      unless message['tool_calls']
        return {
          content: message['content'] || format_accumulated_results(accumulated_tool_results),
          metadata: {
            tool_calls: accumulated_tool_results,
            iterations: iteration
          }
        }
      end

      # Execute all tool calls
      tool_results = execute_tool_calls(message['tool_calls'])
      accumulated_tool_results.concat(tool_results)

      # Check if any tool requires waiting (like sending email)
      if requires_waiting?(tool_results)
        create_waiting_task(message, accumulated_tool_results)
        return {
          content: message['content'] || format_tool_results(tool_results),
          metadata: {
            tool_calls: accumulated_tool_results,
            waiting: true,
            iterations: iteration
          }
        }
      end

      # Add assistant message and tool results to conversation
      messages << {
        role: 'assistant',
        content: message['content'],
        tool_calls: message['tool_calls']
      }

      # Add tool results
      tool_results.each do |result|
        messages << {
          role: 'tool',
          tool_call_id: result[:tool_call_id],
          content: result[:result].to_json
        }
      end

      # If AI provided final content, we're done
      if message['content'] && !message['content'].empty?
        return {
          content: message['content'],
          metadata: {
            tool_calls: accumulated_tool_results,
            iterations: iteration
          }
        }
      end

      # Otherwise, loop and let AI continue with tool results
    end

    # Max iterations reached
    {
      content: "I've completed the available actions. #{format_accumulated_results(accumulated_tool_results)}",
      metadata: {
        tool_calls: accumulated_tool_results,
        max_iterations_reached: true
      }
    }
  end

  def execute_tool_calls(tool_calls)
    tool_calls.map do |tool_call|
      function_name = tool_call.dig('function', 'name')
      arguments = JSON.parse(tool_call.dig('function', 'arguments'))

      Rails.logger.info "Executing tool: #{function_name} with args: #{arguments}"
      
      result = ToolRegistry.execute(@user, function_name, arguments)

      {
        tool_call_id: tool_call['id'],
        function_name: function_name,
        arguments: arguments,
        result: result
      }
    rescue => e
      Rails.logger.error "Tool execution failed: #{e.message}\n#{e.backtrace.join("\n")}"
      {
        tool_call_id: tool_call['id'],
        function_name: function_name,
        arguments: arguments,
        result: { success: false, error: e.message }
      }
    end
  end

  def get_rag_context(query)
    return [] if query.blank?

    # Generate embedding for query
    embedding = generate_embedding(query)
    return [] unless embedding

    # Search similar embeddings
    results = @user.knowledge_entries.search(embedding, limit: 10)

    results.map do |result|
      {
        source: result.source_type,
        content: result.content,
        metadata: result.metadata
      }
    end
  rescue => e
    Rails.logger.error "RAG context retrieval failed: #{e.message}"
    []
  end

  def generate_embedding(text)
    return nil if text.blank?

    # Return a deterministic fake embedding vector (e.g., 1536-dim)
    rng = Random.new(text.hash)
    Array.new(1536) { rng.rand }  # random floats between 0.0 and 1.0

  #   response = @client.embeddings(
  #     parameters: {
  #       model: 'text-embedding-ada-002',
  #       input: text[0..8000]
  #     }
  #   )
  #   response.dig('data', 0, 'embedding')
  # rescue => e
  #   Rails.logger.error "Embedding generation failed: #{e.message}"
  #   nil
  end

  def build_messages(user_input, context, instructions)
    messages = [
      { role: 'system', content: SYSTEM_PROMPT }
    ]

    if instructions.present?
      messages << {
        role: 'system',
        content: "ONGOING INSTRUCTIONS (always follow these):\n#{instructions}" 
      }
    end

    if context.any?
      context_text = context.map do |c|
        "Source: #{c[:source]}\n#{c[:content]}\n---"
      end.join("\n\n")
      messages << {
        role: 'system',
        content: "RELEVANT CONTEXT from your knowledge base:\n#{context_text}"
      }
    end

    # Add recent conversation history
    @conversation.messages.last(10).each do |msg|
      messages << { role: msg.role, content: msg.content }
    end

    messages << { role: 'user', content: user_input }
    messages
  end

  def format_event_description(event_type, event_data)
    case event_type
    when 'gmail_message'
      "NEW EMAIL RECEIVED:\n" \
      "From: #{event_data['from']}\n" \
      "Subject: #{event_data['subject']}\n" \
      "Snippet: #{event_data['snippet']}"
    when 'calendar_event'
      "CALENDAR EVENT:\n" \
      "Type: #{event_data['type']}\n" \
      "Event: #{event_data['summary']}\n" \
      "Time: #{event_data['start']}"
    when /^hubspot_/
      "HUBSPOT EVENT:\n" \
      "Type: #{event_type}\n" \
      "Details: #{event_data.to_json}"
    else
      "EVENT: #{event_type}\n#{event_data.to_json}"
    end
  end

  def requires_waiting?(tool_results)
    tool_results.any? do |result|
      result[:function_name] == 'send_email' && result[:result][:success]
    end
  end

  def create_waiting_task(message, tool_results)
    @user.tasks.create!(
      conversation: @conversation,
      status: 'waiting',
      description: message['content'] || 'Waiting for response',
      context: {
        tool_calls: tool_results,
        waiting_for: 'email_response'
      }
    )
  end

  def format_tool_results(results)
    results.map do |r|
      if r[:result][:success]
        r[:result][:message] || "✓ #{r[:function_name]} completed"
      else
        "✗ #{r[:function_name]} failed: #{r[:result][:error]}"
      end
    end.join("\n")
  end

  def format_accumulated_results(results)
    return '' if results.empty?
    "\n\nActions taken:\n" + format_tool_results(results)
  end
end
