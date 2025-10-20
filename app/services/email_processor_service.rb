class EmailProcessorService
  def initialize(user)
    @user = user
  end

  def process_and_sync(message_id)
    gmail = @user.google_client.gmail_service

    # Skip if already synced
    return if @user.knowledge_entries.exists?(source_type: 'email', source_id: message_id)

    message = gmail.get_user_message('me', message_id, format: 'full')

    # Extract content
    content = extract_email_content(message)
    return if content.blank?

    # Generate embedding
    embedding = generate_embedding(content)
    return unless embedding

    # Store in knowledge base
    @user.knowledge_entries.create!(
      source_type: 'email',
      source_id: message_id,
      content: content,
      embedding: embedding,
      metadata: extract_metadata(message)
    )

    Rails.logger.info "Synced email to knowledge base: #{message_id}"
  rescue => e
    Rails.logger.error "Failed to sync email #{message_id}: #{e.message}"
  end

  def extract_email_content(message)
    subject = get_header(message, 'Subject')
    from = get_header(message, 'From')
    body = extract_body(message)
    "Subject: #{subject}\nFrom: #{from}\n\n#{body}"
  end

  def extract_body(message)
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
        strip_html(decode_base64(part.body.data))
      elsif part.parts.present?
        extract_from_parts(part.parts)
      else
        nil
      end
    end.compact.join("\n")
  end

  def decode_base64(data)
    return '' if data.blank?

    decoded = Base64.urlsafe_decode64(data)
    decoded.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  rescue ArgumentError, Encoding::UndefinedConversionError => e
    Rails.logger.error "Base64 decode error: #{e.message}"
    ''
  end

  def strip_html(html)
    html.gsub(/<[^>]*>/, ' ').gsub(/\s+/, ' ').strip
  end

  def get_header(message, name)
    header = message.payload.headers.find { |h| h.name.downcase == name.downcase }
    header&.value || ''
  end

  def extract_metadata(message)
    {
      subject: get_header(message, 'Subject'),
      from: get_header(message, 'From'),
      to: get_header(message, 'To'),
      date: get_header(message, 'Date'),
      thread_id: message.thread_id
    }
  end

  private

  def generate_embedding(text)
    return nil if text.blank?

    truncated_text = text[0..32000]

    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    response = client.embeddings(
      parameters: {
        model: 'text-embedding-ada-002',
        input: truncated_text
      }
    )
    response.dig('data', 0, 'embedding')
  rescue => e
    Rails.logger.error "Failed to generate embedding: #{e.message}"
    nil
  end
end
