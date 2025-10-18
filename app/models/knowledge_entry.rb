class KnowledgeEntry < ApplicationRecord
  belongs_to :user

  has_neighbors :embedding
end
