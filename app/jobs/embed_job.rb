class EmbedJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    doc = Document.find(document_id)
    embedding = EmbeddingService.create_embedding(doc.content)
    doc.update!(embedding: embedding)
  end
end
