# YouTube Companion Dashboard

A Ruby on Rails application that connects to the YouTube Data API v3 to help users manage their uploaded videos in detail.

## Features

- 📹 Fetch and display YouTube video details
- ✏️ Update video title and description directly on YouTube
- 💬 View, post, reply to, and delete comments
- 📝 Add personal notes for video improvements
- 📊 Track video statistics (views, likes, comments)
- 🔐 OAuth 2.0 authentication with YouTube
- 📋 Comprehensive event logging

## Tech Stack

- **Ruby**: 3.3.6
- **Rails**: 8.0.3
- **Database**: MySQL
- **Frontend**: Tailwind CSS
- **APIs**: Google YouTube Data API v3

## Prerequisites

- Ruby 3.3.6
- MySQL
- YouTube Data API v3 credentials (Client ID, Client Secret, API Key)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd youtube_companion
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Configuration

The database is configured to use MySQL with the following credentials:
- Username: `root`
- Password: `qwerty`
- Development Database: `youtube_companion_development`
- Test Database: `youtube_companion_test`

Update `config/database.yml` if your credentials differ.

### 4. Create and Setup Database

```bash
rails db:create
rails db:migrate
```

### 5. Configure YouTube API Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable YouTube Data API v3
4. Create OAuth 2.0 credentials (Client ID and Client Secret)
5. Create an API Key
6. Add authorized redirect URI: `http://localhost:3000/oauth/callback`

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```
YOUTUBE_API_KEY=your_api_key_here
YOUTUBE_CLIENT_ID=your_client_id_here
YOUTUBE_CLIENT_SECRET=your_client_secret_here
YOUTUBE_REDIRECT_URI=http://localhost:3000/oauth/callback
```

### 6. Start the Server

```bash
rails server
```

Visit `http://localhost:3000`

## Database Schema

### Videos Table

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| youtube_video_id | string | YouTube video ID (unique, indexed) |
| title | string | Video title |
| description | text | Video description |
| thumbnail_url | string | Video thumbnail URL |
| published_at | datetime | Video publish date |
| view_count | integer | Number of views (default: 0) |
| like_count | integer | Number of likes (default: 0) |
| comment_count | integer | Number of comments (default: 0) |
| created_at | datetime | Record creation timestamp |
| updated_at | datetime | Record update timestamp |

### Notes Table

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| video_id | bigint | Foreign key to videos table |
| content | text | Note content |
| created_at | datetime | Record creation timestamp |
| updated_at | datetime | Record update timestamp |

**Indexes:**
- `video_id` (foreign key index)

**Foreign Keys:**
- `video_id` references `videos(id)`

### Event Logs Table

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| event_type | string | Type of event (indexed) |
| event_data | text | Event data in JSON format |
| ip_address | string | Request IP address |
| user_agent | string | Request user agent |
| created_at | datetime | Event timestamp (indexed) |
| updated_at | datetime | Record update timestamp |

**Indexes:**
- `event_type`
- `created_at`

**Event Types:**
- `video_fetched` - Video added to dashboard
- `video_viewed` - Video details page viewed
- `video_synced` - Video synced from YouTube
- `video_updated` - Video updated on YouTube
- `note_created` - Note added
- `note_updated` - Note updated
- `note_deleted` - Note deleted
- `comment_created` - Comment posted
- `comment_reply_created` - Reply posted
- `comment_deleted` - Comment deleted

## API Endpoints

### OAuth Authentication

| Method | Path | Description |
|--------|------|-------------|
| GET | `/oauth/authorize` | Start YouTube OAuth flow |
| GET | `/oauth/callback` | OAuth callback handler |
| DELETE | `/oauth/revoke` | Revoke YouTube connection |

### Videos

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| GET | `/` | List all videos | No |
| GET | `/videos/:id` | Show video details | No |
| GET | `/videos/new` | New video form | No |
| POST | `/videos` | Add video by URL/ID | No |
| POST | `/videos/:id/sync` | Sync video from YouTube | Yes (OAuth) |
| PATCH | `/videos/:id` | Update video on YouTube | Yes (OAuth) |
| DELETE | `/videos/:id` | Remove video from database | No |

### Notes

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| POST | `/videos/:video_id/notes` | Create note | No |
| PATCH | `/videos/:video_id/notes/:id` | Update note | No |
| DELETE | `/videos/:video_id/notes/:id` | Delete note | No |

### Comments

| Method | Path | Description | Auth Required |
|--------|------|-------------|---------------|
| GET | `/videos/:video_id/comments` | List comments | Yes (OAuth) |
| POST | `/videos/:video_id/comments` | Post comment | Yes (OAuth) |
| POST | `/videos/:video_id/comments/reply` | Reply to comment | Yes (OAuth) |
| DELETE | `/videos/:video_id/comments/:id` | Delete comment | Yes (OAuth) |

## Usage Guide

### 1. Connect YouTube Account

Click "Connect YouTube" in the navigation bar to authorize the application with your YouTube account. This enables:
- Video updates
- Comment management
- Real-time statistics sync

### 2. Add a Video

1. Click "Add Video" button
2. Enter YouTube video URL or video ID
3. Video details will be fetched automatically

### 3. Manage Video

On the video details page, you can:
- Watch the video (embedded player)
- View statistics (views, likes, comments)
- Edit title and description (requires YouTube connection)
- Sync latest stats from YouTube
- Add personal notes
- View and manage comments

### 4. Manage Comments

1. Click "View & Manage Comments" on video page
2. Post new comments
3. Reply to existing comments
4. Delete your comments

### 5. Add Notes

In the video details sidebar:
1. Type your note in the text area
2. Click "Add Note"
3. Notes are stored locally in the database
4. Delete notes anytime

## Project Structure

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── videos_controller.rb
│   ├── notes_controller.rb
│   ├── comments_controller.rb
│   ├── o_auth_controller.rb
│   └── concerns/
│       └── youtube_authentication.rb
├── models/
│   ├── video.rb
│   ├── note.rb
│   └── event_log.rb
├── services/
│   └── youtube_service.rb
└── views/
    ├── layouts/
    │   └── application.html.erb
    ├── videos/
    │   ├── index.html.erb
    │   ├── show.html.erb
    │   └── new.html.erb
    └── comments/
        └── index.html.erb
```

## Event Logging

All user actions are logged to the `event_logs` table with:
- Event type
- Event data (JSON)
- IP address
- User agent
- Timestamp

View logs in Rails console:

```ruby
# Recent events
EventLog.recent.limit(10)

# Events by type
EventLog.by_type('video_fetched')

# All event types
EventLog.EVENT_TYPES
```

## Development

### Run Rails Console

```bash
rails console
```

### Check Routes

```bash
rails routes
```

### Database Migrations

```bash
rails db:migrate
rails db:rollback  # Rollback last migration
```

## License

This project is built for educational purposes.
