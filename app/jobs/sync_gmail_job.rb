class SyncGmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    gmail = user.google_client.gmail_service

    # Get messages
    result = gmail.list_user_messages('me', max_results: 10)

    return unless result.messages

    result.messages.each do |message_ref|
      next if user.integrations_data.exists?(
        integration_type: 'gmail',
        external_id: message_ref.id
      )

      begin
        message = gmail.get_user_message('me', message_ref.id, format: 'full')

        # Store in integrations_data
        user.integrations_data.create!(
          integration_type: 'gmail',
          external_id: message.id,
          data: message.to_h,
          synced_at: Time.now
        )

        # Create embedding
        content = extract_email_content(message)
        next if content.blank?

        embedding = generate_embedding(content)

        user.knowledge_entries.create!(
          source_type: 'email',
          source_id: message.id,
          content:,
          embedding:,
          metadata: {
            subject: get_header(message, 'Subject'),
            from: get_header(message, 'From'),
            to: get_header(message, 'To'),
            date: get_header(message, 'Date'),
            thread_id: message.thread_id
          }
        )
      rescue => e
        Rails.logger.error "Failed to process email #{message_ref.id}: #{e.message}"
        next
      end
    end
  end

  private

  def extract_email_content(message)
    subject = get_header(message, 'Subject')
    from = get_header(message, 'From')
    body = extract_body(message)

    "Subject: #{subject}\nFrom: #{from}\n\n#{body}"
  end

  def extract_body(message)
    # Try to get the body from different locations
    if message.payload.body&.data.present?
      decode_base64(message.payload.body.data)
    elsif message.payload.parts.present?
      extract_from_parts(message.payload.parts)
    else
      ''
    end
  rescue => e
    Rails.logger.error "Error extracting body: #{e.message}"
    ''
  end

  def extract_from_parts(parts)
    parts.map do |part|
      if part.mime_type == 'text/plain' && part.body&.data.present?
        decode_base64(part.body.data)
      elsif part.mime_type == 'text/html' && part.body&.data.present?
        # Fallback to HTML if no plain text
        strip_html(decode_base64(part.body.data))
      elsif part.parts.present?
        # Recursive for nested parts
        extract_from_parts(part.parts)
      else
        nil
      end
    end.compact.join("\n")
  end

  def decode_base64(data)
    return '' if data.blank?

    # Gmail uses URL-safe base64
    decoded = Base64.urlsafe_decode64(data)

    # Remove non-UTF8 characters
    decoded.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  rescue ArgumentError, Encoding::UndefinedConversionError => e
    Rails.logger.error "Base64 decode error: #{e.message}"
    ''
  end

  def strip_html(html)
    # Simple HTML stripping
    html.gsub(/<[^>]*>/, ' ').gsub(/\s+/, ' ').strip
  end

  def get_header(message, name)
    header = message.payload.headers.find { |h| h.name.downcase == name.downcase }
    header&.value || ''
  end

  def generate_embedding(text)
  #   return nil if text.blank?

  #   # Limit text length for embedding (8k tokens ≈ 32k chars)
  #   truncated_text = text[0..32000]

  #   client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  #   response = client.embeddings(
  #     parameters: {
  #       model: 'text-embedding-3-small',
  #       input: truncated_text
  #     }
  #   )
  #   response.dig('data', 0, 'embedding')
  # rescue => e
  #   Rails.logger.error "Failed to generate embedding: #{e.message}"
  #   nil

    # Return a deterministic fake embedding vector (e.g., 1536-dim)
    rng = Random.new(text.hash)
    Array.new(1536) { rng.rand }  # random floats between 0.0 and 1.0
  end
end
