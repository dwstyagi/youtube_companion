class Video < ApplicationRecord
  has_many :notes, dependent: :destroy

  validates :youtube_video_id, presence: true, uniqueness: true
  validates :title, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_views, -> { order(view_count: :desc) }
end
