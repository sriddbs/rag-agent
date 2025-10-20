class SyncSingleHubspotContactJob < ApplicationJob
  queue_as :default

  def perform(user_id, contact_id)
    user = User.find(user_id)
    client = user.hubspot_client

    # Get contact details
    contact = client.get_contact(contact_id)

    # Format content
    content = format_contact_content(contact)
    return if content.blank?

    # Generate embedding
    embedding = generate_embedding(content)
    return unless embedding

    # Update or create in knowledge base
    knowledge_entry = user.knowledge_entries.find_or_initialize_by(
      source_type: 'hubspot_contact',
      source_id: contact_id
    )

    knowledge_entry.update!(
      content: content,
      embedding: embedding,
      metadata: contact['properties']
    )

    Rails.logger.info "Synced Hubspot contact to knowledge base: #{contact_id}"
  rescue => e
    Rails.logger.error "Failed to sync Hubspot contact #{contact_id}: #{e.message}"
  end

  private

  def format_contact_content(contact)
    props = contact['properties'] || {}
    [
      "Contact: #{props['firstname']} #{props['lastname']}",
      "Email: #{props['email']}",
      "Phone: #{props['phone']}",
      "Company: #{props['company']}",
      "Job Title: #{props['jobtitle']}"
    ].compact.join("\n")
  end

  def generate_embedding(text)
    client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    response = client.embeddings(
      parameters: {
        model: 'text-embedding-ada-002',
        input: text
      }
    )
    response.dig('data', 0, 'embedding')
  rescue => e
    Rails.logger.error "Failed to generate embedding: #{e.message}"
    nil
  end
end
