class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.string :status # pending, in_progress, waiting, completed, failed
      t.text :description
      t.jsonb :context
      t.jsonb :steps_completed
      t.datetime :completed_at
      t.timestamps
    end
  end
end
