class SyncHubspotJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    client = user.hubspot_client

    # Sync contacts
    contacts_data = client.get_all_contacts
    
    contacts_data.dig('results')&.each do |contact|
      next if user.integrations_data.exists?(
        integration_type: 'hubspot',
        external_id: contact['id']
      )

      user.integrations_data.create!(
        integration_type: 'hubspot',
        external_id: contact['id'],
        data: contact,
        synced_at: Time.now
      )

      # Create embedding
      content = format_contact_content(contact)
      embedding = generate_embedding(content)

      user.knowledge_entries.create!(
        source_type: 'hubspot_contact',
        source_id: contact['id'],
        content: content,
        embedding: embedding,
        metadata: contact['properties']
      )
    end
  end

  private

  def format_contact_content(contact)
    props = contact['properties']
    [
      "Contact: #{props['firstname']} #{props['lastname']}",
      "Email: #{props['email']}",
      "Phone: #{props['phone']}",
      "Company: #{props['company']}"
    ].compact.join("\n")
  end

  def generate_embedding(text)
    # client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
    # response = client.embeddings(
    #   parameters: {
    #     model: 'text-embedding-ada-002',
    #     input: text
    #   }
    # )
    # response.dig('data', 0, 'embedding')
    # Return a deterministic fake embedding vector (e.g., 1536-dim)
    rng = Random.new(text.hash)
    Array.new(1536) { rng.rand }  # random floats between 0.0 and 1.0
  end
end
