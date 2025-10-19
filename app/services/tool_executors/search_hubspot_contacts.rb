module ToolExecutors
  class SearchHubspotContacts
    def initialize(user)
      @user = user
    end

    def execute(args)
      query = args['query']

      # Search in knowledge_entries first
      embedding = generate_embedding(query)
      results = @user.knowledge_entries
        .where(source_type: 'hubspot_contact')
        .search(embedding, limit: 5)

      {
        success: true,
        message: "Found #{results.count} contacts",
        data: results.map do |r|
          r.metadata.slice('id', 'email', 'firstname', 'lastname', 'phone')
        end
      }
    end

    private

    def generate_embedding(text)
      # Return a deterministic fake embedding vector (e.g., 1536-dim)
      rng = Random.new(text.hash)
      Array.new(1536) { rng.rand }  # random floats between 0.0 and 1.0

      # client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
      # response = client.embeddings(
      #   parameters: {
      #     model: 'text-embedding-ada-002',
      #     input: text
      #   }
      # )
      # response.dig('data', 0, 'embedding')
    end
  end
end
