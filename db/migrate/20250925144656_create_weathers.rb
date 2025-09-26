class CreateWeathers < ActiveRecord::Migration[8.0]
  def change
    create_table :weathers do |t|
      t.string :temperature
      t.string :temp_min
      t.string :temp_max
      t.string :description
      t.string :zip_code
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
