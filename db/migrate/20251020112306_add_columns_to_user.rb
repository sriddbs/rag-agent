class AddColumnsToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_email_check_at, :datetime
    add_column :users, :last_calendar_check_at, :datetime
    add_column :users, :last_hubspot_check_at, :datetime
  end
end
