class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :format, null: false
      t.string :status, default: "pending", null: false
      t.text :filters
      t.binary :file_data
      t.boolean :email_notification, default: false
      t.datetime :completed_at
      t.text :error_message

      t.timestamps
    end

    add_index :reports, :status
    add_index :reports, :format
    add_index :reports, [:user_id, :status]
    add_index :reports, :created_at
  end
end
