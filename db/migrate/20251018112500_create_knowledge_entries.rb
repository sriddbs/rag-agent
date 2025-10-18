class CreateKnowledgeEntries < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector" unless extension_enabled?("vector")

    create_table :knowledge_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :source_type # email, hubspot_contact, hubspot_note
      t.string :source_id
      t.text :content
      t.jsonb :metadata
      t.timestamps
    end

    # Add vector column via raw SQL so dimension is respected
    execute <<~SQL
      ALTER TABLE knowledge_entries
      ADD COLUMN embedding vector(1536);
    SQL

    # Make the index creation reversible
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE INDEX index_knowledge_entries_on_embedding
          ON knowledge_entries USING ivfflat (embedding vector_cosine_ops)
          WITH (lists = 100);
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP INDEX IF EXISTS index_knowledge_entries_on_embedding;
        SQL
      end
    end
  end
end
