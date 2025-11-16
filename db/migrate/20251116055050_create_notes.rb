class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :video, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
