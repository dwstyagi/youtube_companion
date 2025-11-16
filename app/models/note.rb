class Note < ApplicationRecord
  belongs_to :video

  validates :content, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
