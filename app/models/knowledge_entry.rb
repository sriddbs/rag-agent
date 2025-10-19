class KnowledgeEntry < ApplicationRecord
  belongs_to :user

  has_neighbors :embedding

  def self.search(query_embedding, limit: 10)
    nearest_neighbors(:embedding, query_embedding, distance: "cosine")
      .limit(limit)
  end
end
