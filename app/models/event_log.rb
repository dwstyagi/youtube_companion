class EventLog < ApplicationRecord
  validates :event_type, presence: true

  # Event types constants
  EVENT_TYPES = {
    video_fetched: 'video_fetched',
    video_updated: 'video_updated',
    comment_created: 'comment_created',
    comment_deleted: 'comment_deleted',
    note_created: 'note_created',
    note_updated: 'note_updated',
    note_deleted: 'note_deleted'
  }.freeze

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }

  # Class method to log events
  def self.log_event(event_type, event_data = {}, request = nil)
    create!(
      event_type: event_type,
      event_data: event_data.to_json,
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    )
  end
end
