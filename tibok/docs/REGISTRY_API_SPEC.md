# Tibok Plugin Registry API Specification

## Overview

The Plugin Registry API is a serverless API hosted on Cloudflare Workers that manages plugin discovery, distribution, and verification for the Tibok plugin ecosystem.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Cloudflare Edge Network                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │   Worker     │    │   R2 Bucket   │    │   KV Namespace    │  │
│  │   (API)      │◄──►│  (Plugins)    │    │  (Cache/Config)   │  │
│  └──────────────┘    └──────────────┘    └──────────────────┘  │
│         │                                        │               │
│         └────────────────┬───────────────────────┘               │
│                          │                                        │
│  ┌──────────────────────▼───────────────────────────────────┐  │
│  │                    D1 Database                             │  │
│  │          (Plugins, Users, Downloads, Reviews)              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Base URL

```
Production: https://plugins.tibok.app/api/v1
Staging:    https://staging-plugins.tibok.app/api/v1
```

## Authentication

Most endpoints are public. Admin endpoints require Bearer token authentication:

```http
Authorization: Bearer <token>
```

## Endpoints

### Registry

#### GET /registry.json

Returns the complete plugin registry. This is the primary endpoint used by Tibok to discover available plugins.

**Response:**
```json
{
  "version": "1.0",
  "generated_at": "2025-01-03T12:00:00Z",
  "registry_signature": "base64-encoded-ed25519-signature",
  "plugins": [
    {
      "identifier": "com.example.lorem-ipsum",
      "name": "Lorem Ipsum Generator",
      "version": "1.0.0",
      "description": "Generate placeholder text in your documents",
      "icon": "text.word.spacing",
      "author": "Example Developer",
      "plugin_type": "script",
      "trust_tier": "verified",
      "permissions": ["slash-commands", "insert-text"],
      "downloads": 1234,
      "rating": 4.5,
      "rating_count": 42,
      "minimum_tibok_version": "1.0.0",
      "download_url": "https://plugins.tibok.app/packages/com.example.lorem-ipsum/1.0.0/bundle.zip",
      "size": 12345,
      "homepage": "https://github.com/example/lorem-ipsum",
      "repository": "https://github.com/example/lorem-ipsum",
      "license": "MIT",
      "keywords": ["lorem", "ipsum", "placeholder", "text"],
      "signature": {
        "algorithm": "ed25519",
        "public_key": "base64-encoded-public-key",
        "signature": "base64-encoded-signature",
        "content_hash": "sha256-hex-hash"
      },
      "updated_at": "2025-01-01T10:00:00Z"
    }
  ],
  "featured": ["com.example.lorem-ipsum", "com.example.markdown-table"],
  "categories": [
    {
      "slug": "productivity",
      "name": "Productivity",
      "description": "Boost your writing workflow",
      "icon": "bolt.fill",
      "count": 12
    }
  ]
}
```

**Caching:**
- CDN cache: 5 minutes
- Stale-while-revalidate: 1 hour
- Client should cache for 1 hour

### Plugin Details

#### GET /plugins/{identifier}

Returns detailed information about a specific plugin.

**Response:**
```json
{
  "identifier": "com.example.lorem-ipsum",
  "name": "Lorem Ipsum Generator",
  "version": "1.0.0",
  "description": "Generate placeholder text in your documents",
  "long_description": "Markdown content with full plugin documentation...",
  "changelog": "## 1.0.0\n- Initial release",
  "icon": "text.word.spacing",
  "author": {
    "name": "Example Developer",
    "email": "developer@example.com",
    "url": "https://example.com"
  },
  "plugin_type": "script",
  "trust_tier": "verified",
  "permissions": ["slash-commands", "insert-text"],
  "screenshots": [
    "https://plugins.tibok.app/assets/com.example.lorem-ipsum/screenshot-1.png"
  ],
  "versions": [
    {
      "version": "1.0.0",
      "download_url": "https://plugins.tibok.app/packages/com.example.lorem-ipsum/1.0.0/bundle.zip",
      "size": 12345,
      "minimum_tibok_version": "1.0.0",
      "released_at": "2025-01-01T10:00:00Z"
    }
  ],
  "stats": {
    "downloads": 1234,
    "downloads_week": 56,
    "downloads_month": 234,
    "rating": 4.5,
    "rating_count": 42
  },
  "homepage": "https://github.com/example/lorem-ipsum",
  "repository": "https://github.com/example/lorem-ipsum",
  "license": "MIT",
  "keywords": ["lorem", "ipsum", "placeholder", "text"],
  "created_at": "2024-12-01T00:00:00Z",
  "updated_at": "2025-01-01T10:00:00Z"
}
```

### Plugin Download

#### GET /packages/{identifier}/{version}/bundle.zip

Downloads a plugin bundle. Redirects to R2 signed URL.

**Headers:**
```http
X-Download-Token: optional-tracking-token
```

**Response:**
- 302 redirect to signed R2 URL
- Download tracking incremented

### Search

#### GET /search

Search and filter plugins.

**Query Parameters:**
- `q` - Search query (matches name, description, keywords)
- `category` - Filter by category slug
- `tier` - Filter by trust tier (official, verified, community)
- `type` - Filter by plugin type (reserved for future use, all plugins are currently "script")
- `sort` - Sort by: relevance, downloads, rating, updated, name
- `page` - Page number (default: 1)
- `limit` - Results per page (default: 20, max: 100)

**Response:**
```json
{
  "results": [...],
  "total": 42,
  "page": 1,
  "limit": 20,
  "has_more": true
}
```

### Categories

#### GET /categories

List all plugin categories.

**Response:**
```json
{
  "categories": [
    {
      "slug": "productivity",
      "name": "Productivity",
      "description": "Boost your writing workflow",
      "icon": "bolt.fill",
      "count": 12
    }
  ]
}
```

### Plugin Submission (Authenticated)

#### POST /plugins

Submit a new plugin for review.

**Request:**
```json
{
  "manifest": { ... },
  "bundle_url": "https://github.com/user/repo/releases/download/v1.0.0/plugin.zip",
  "source_url": "https://github.com/user/repo"
}
```

**Response:**
```json
{
  "submission_id": "sub_abc123",
  "status": "pending_review",
  "estimated_review_time": "2-5 business days"
}
```

#### PUT /plugins/{identifier}

Update an existing plugin.

#### GET /submissions

List developer's plugin submissions and their status.

### Reviews

#### GET /plugins/{identifier}/reviews

Get reviews for a plugin.

**Query Parameters:**
- `sort` - Sort by: recent, helpful, rating
- `page` - Page number
- `limit` - Results per page

#### POST /plugins/{identifier}/reviews

Submit a review (requires Tibok account).

**Request:**
```json
{
  "rating": 5,
  "title": "Great plugin!",
  "body": "This plugin has saved me so much time..."
}
```

### Analytics (Authenticated)

#### GET /analytics/{identifier}

Get download and usage analytics for a plugin (developer only).

**Response:**
```json
{
  "downloads": {
    "total": 1234,
    "last_7_days": [12, 15, 8, 22, 18, 14, 11],
    "last_30_days": 234
  },
  "versions": {
    "1.0.0": 800,
    "1.0.1": 434
  },
  "tibok_versions": {
    "1.0.0": 50,
    "1.0.1": 84
  }
}
```

## Admin Endpoints

### POST /admin/verify

Mark a plugin as verified after security review.

### POST /admin/unverify

Remove verified status from a plugin.

### POST /admin/feature

Add a plugin to featured list.

### DELETE /admin/plugins/{identifier}

Remove a plugin from the registry.

### POST /admin/regenerate

Regenerate and sign the registry.json file.

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "PLUGIN_NOT_FOUND",
    "message": "Plugin with identifier 'com.example.foo' not found",
    "details": {}
  }
}
```

**Error Codes:**
- `PLUGIN_NOT_FOUND` - Plugin does not exist
- `VERSION_NOT_FOUND` - Requested version does not exist
- `INVALID_MANIFEST` - Manifest validation failed
- `SIGNATURE_INVALID` - Plugin signature verification failed
- `PERMISSION_DENIED` - Authentication required or insufficient permissions
- `RATE_LIMITED` - Too many requests
- `INTERNAL_ERROR` - Server error

## Rate Limits

| Endpoint | Limit |
|----------|-------|
| GET /registry.json | 100/minute |
| GET /plugins/* | 60/minute |
| GET /search | 30/minute |
| POST /plugins | 10/hour |
| POST /reviews | 5/minute |

Rate limit headers:
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1704288000
```

## Cloudflare Worker Implementation

### wrangler.toml

```toml
name = "tibok-plugin-registry"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[[r2_buckets]]
binding = "PLUGINS"
bucket_name = "tibok-plugins"

[[kv_namespaces]]
binding = "CACHE"
id = "xxx"

[[d1_databases]]
binding = "DB"
database_name = "tibok-registry"
database_id = "xxx"

[vars]
REGISTRY_PUBLIC_KEY = "base64-public-key"
```

### Database Schema

```sql
CREATE TABLE plugins (
    identifier TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    author TEXT,
    author_email TEXT,
    homepage TEXT,
    repository TEXT,
    license TEXT,
    plugin_type TEXT DEFAULT 'script', -- All marketplace plugins are 'script'
    trust_tier TEXT DEFAULT 'community',
    featured BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE plugin_versions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plugin_identifier TEXT NOT NULL,
    version TEXT NOT NULL,
    minimum_tibok_version TEXT,
    permissions TEXT, -- JSON array
    signature TEXT, -- JSON object
    bundle_path TEXT NOT NULL,
    bundle_size INTEGER,
    changelog TEXT,
    released_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plugin_identifier) REFERENCES plugins(identifier),
    UNIQUE(plugin_identifier, version)
);

CREATE TABLE plugin_downloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plugin_identifier TEXT NOT NULL,
    version TEXT NOT NULL,
    downloaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    tibok_version TEXT,
    os_version TEXT,
    FOREIGN KEY (plugin_identifier) REFERENCES plugins(identifier)
);

CREATE TABLE plugin_reviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plugin_identifier TEXT NOT NULL,
    user_id TEXT NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title TEXT,
    body TEXT,
    helpful_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plugin_identifier) REFERENCES plugins(identifier)
);

CREATE TABLE keywords (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plugin_identifier TEXT NOT NULL,
    keyword TEXT NOT NULL,
    FOREIGN KEY (plugin_identifier) REFERENCES plugins(identifier)
);

CREATE INDEX idx_keywords_keyword ON keywords(keyword);
CREATE INDEX idx_downloads_plugin ON plugin_downloads(plugin_identifier);
CREATE INDEX idx_versions_plugin ON plugin_versions(plugin_identifier);
```

## Security Considerations

1. **Bundle Signing**: All verified plugins must have valid Ed25519 signatures
2. **Registry Signing**: The registry.json is signed to prevent tampering
3. **Content Hashing**: Plugin bundles are verified against stored SHA-256 hashes
4. **R2 Signed URLs**: Download links expire after 1 hour
5. **Rate Limiting**: Prevents abuse of submission and search endpoints
6. **Input Validation**: All user input is validated and sanitized

## Versioning

The API uses URL-based versioning (`/api/v1/`). Breaking changes will result in a new version. The current version will be supported for at least 12 months after a new version is released.
