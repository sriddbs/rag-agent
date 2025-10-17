class CreateOauthCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :oauth_credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_uid
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.jsonb :raw
      t.timestamps
    end
  end
end
