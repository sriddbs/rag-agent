class CreateIntegrationsData < ActiveRecord::Migration[8.0]
  def change
    create_table :integrations_data do |t|
      t.references :user, null: false, foreign_key: true
      t.string :integration_type # gmail, calendar, hubspot
      t.string :external_id
      t.jsonb :data
      t.datetime :synced_at
      t.timestamps
    end
  end
end
