class CreateOngoingInstructions < ActiveRecord::Migration[8.0]
  def change
    create_table :ongoing_instructions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :instruction
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
