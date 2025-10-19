module ToolExecutors
  class SearchEmails
    def initialize(user)
      @user = user
    end

    def execute(args)
      query = args['query']

      # Search in knowledge_entries
      embedding = generate_embedding(query)
      results = @user.knowledge_entries
        .where(source_type: 'email')
        .search(embedding, limit: 5)

      {
        success: true,
        message: "Found #{results.count} relevant emails",
        data: results.map do |r|
          {
            subject: r.metadata['subject'],
            from: r.metadata['from'],
            date: r.metadata['date'],
            snippet: r.content[0..200]
          }
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
