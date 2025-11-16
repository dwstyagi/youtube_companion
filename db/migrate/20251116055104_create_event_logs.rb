class CreateEventLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :event_logs do |t|
      t.string :event_type, null: false
      t.text :event_data
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :event_logs, :event_type
    add_index :event_logs, :created_at
  end
end
