class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.string :youtube_video_id, null: false
      t.string :title
      t.text :description
      t.string :thumbnail_url
      t.datetime :published_at
      t.integer :view_count, default: 0
      t.integer :like_count, default: 0
      t.integer :comment_count, default: 0

      t.timestamps
    end

    add_index :videos, :youtube_video_id, unique: true
  end
end
