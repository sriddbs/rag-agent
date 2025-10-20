class KnowledgeEntry < ApplicationRecord
  belongs_to :user

  has_neighbors :embedding

  def self.search(query_embedding, limit: 10)
    vector = query_embedding.join(",")

    find_by_sql([<<~SQL, limit])
      SELECT *, (embedding <=> '[#{vector}]') AS distance
      FROM #{table_name}
      ORDER BY embedding <=> '[#{vector}]'
      LIMIT ?
    SQL
  end
end
