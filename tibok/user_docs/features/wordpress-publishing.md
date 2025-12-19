# WordPress Publishing

Tibok can publish your markdown documents directly to WordPress sites using either the REST API or email posting.

## Quick Start

1. Go to **Settings > Plugins** and enable the **WordPress Export** plugin
2. Go to **Settings > WordPress** to configure your connection
3. Choose your publishing method:
   - **REST API** - Direct publishing to WordPress.com or self-hosted sites
   - **Email** - Post by sending email to your site's posting address

## REST API Publishing

### Requirements

- WordPress 5.6+ (self-hosted) or WordPress.com site (not P2)
- Application Password for authentication

### Setup

1. **Create Application Password:**
   - **Self-hosted:** Install [Application Passwords plugin](https://wordpress.org/plugins/application-passwords/) or upgrade to WordPress 5.6+
   - **WordPress.com:** Go to [Security Settings](https://wordpress.com/me/security/two-step) and create an Application Password

2. **Configure in tibok:**
   - Site URL: `https://yourblog.com` (no trailing slash needed)
   - Username: Your WordPress username
   - Application Password: Paste the password (stored securely in macOS Keychain)

3. **Test Connection:**
   - Click "Test Connection" to verify settings
   - If successful, you're ready to publish!

### Publishing

Use the Command Palette to publish:
- Press **⌘K** → search "Publish to WordPress"
- Alternatively: **Go > Command Palette** → "Publish to WordPress"

Your post will:
- Open in your default browser after publishing
- Copy the URL to clipboard
- Show success notification with link

### Features

- **Frontmatter support** - Override defaults with document metadata
- **Image upload** - Local images automatically uploaded to WordPress Media Library
- **Category/tag creation** - Non-existent categories and tags created automatically
- **Draft/publish control** - Set post status via frontmatter or settings
- **Multi-blog support** - WordPress.com users can switch between blogs

## Email Publishing

### Requirements

- WordPress site with [Jetpack](https://jetpack.com) or email-to-post feature
- Posting email address from your WordPress settings

### Setup

1. **Get Posting Email:**
   - **WordPress.com:** Settings > Writing > Post by Email
   - **Self-hosted:** Install Jetpack → Settings > Writing → Post by Email

2. **Configure in tibok:**
   - Go to Settings > WordPress > Email Settings
   - Enter your unique posting email address

### Publishing

Email publishing requires manual composition:
- Copy your markdown content
- Create new email in your mail app
- Paste content with frontmatter-based shortcodes (see format below)
- Send to your WordPress posting email address

### Email Format

Tibok includes WordPress shortcodes in the email for metadata:

```
[category Blog] [category Tutorial]
[tags markdown, writing]
[status draft]
[excerpt Post summary here]

# Post Title

Post content here...
```

**Shortcode Format:**
- Categories: `[category Name]` - separate shortcode for each category
- Tags: `[tags tag1, tag2, tag3]` - comma-separated in single shortcode
- Status: `[status draft|publish|pending|private]`
- Excerpt: `[excerpt Your text here]`

## Frontmatter Support

Override publishing settings using YAML frontmatter:

```yaml
---
title: My Post Title
description: Post excerpt/summary
categories: [Blog, Tutorial]
tags: [markdown, writing]
draft: true
author: John Doe
---

Post content starts here...
```

### Frontmatter Fields

| Field | Description | API | Email |
|-------|-------------|-----|-------|
| `title` | Post title | ✅ | ✅ |
| `description` | Post excerpt | ✅ | ✅ |
| `categories` | Category names | ✅ | ✅ |
| `tags` | Tag names | ✅ | ✅ |
| `draft` | Draft status (`true`/`false`) | ✅ | ✅ |
| `author` | Author display name (see note below) | ✅ | ❌ |
| `layout` | Jekyll/Hugo only (ignored by WordPress) | ❌ | ❌ |

**Author Field:**
- **API:** Sends display name string. If the author doesn't exist on WordPress, the authenticated user (Application Password owner) will be used as the author.
- **Email:** Not supported in email shortcode format
- **Note:** WordPress uses the authenticated user by default, so this field is optional

**Layout Field:**
- Used by Jekyll and Hugo static site generators for page templates
- **Ignored by WordPress** - WordPress uses themes and page templates configured in the admin
- Safe to include if you also publish to Jekyll/Hugo sites

## P2 Site Limitations

**P2 sites** (WordPress.com's team collaboration workspaces) use OAuth authentication and **don't support Application Passwords**.

### To post to P2 sites:

✅ **Use Email Posting** (recommended)
- Configure your P2's posting email address in Settings > WordPress > Email Settings
- Posts will be created when you export via email
- Full frontmatter support

❌ **REST API Publishing**
- Not supported for P2 sites
- Use a standard WordPress.com blog or self-hosted site instead

### Why P2 is Different

P2 uses WordPress.com's OAuth authentication system rather than Application Passwords. Adding OAuth support would require:
- Browser-based login flow
- OAuth token management
- Additional complexity

For P2 users, email posting provides the same functionality without authentication complexity.

## Image Handling

When publishing via REST API, tibok automatically:

1. **Detects local images** in your markdown (`![](./images/photo.jpg)`)
2. **Uploads to WordPress Media Library** using the Media API
3. **Updates image URLs** in the published post
4. **Shows upload status** (e.g., "Uploaded 3 images")

Remote images (`https://...`) are left unchanged.

## Multi-Blog Support (WordPress.com)

WordPress.com users can manage multiple blogs with one Application Password:

1. Click **Discover Blogs** in Settings > WordPress
2. All your blogs appear in the dropdown
3. Select the blog you want to publish to
4. Publish normally - posts go to the selected blog

## Troubleshooting

### "Authentication failed"
- Verify your Application Password is correct
- Check username matches exactly
- Ensure site URL is correct (no `/wp-admin` or other paths)

### "REST API is not accessible"
- Self-hosted: Ensure WordPress 5.6+ or Application Passwords plugin installed
- Check that REST API is enabled (Settings > Permalinks > Save to flush)
- Verify no security plugins are blocking `/wp-json/` endpoints

### "P2 site detected"
- P2 sites don't support Application Passwords
- Use email posting instead (see P2 Limitations above)

### Images not uploading
- Check file size (>10MB may fail)
- Verify WordPress Media Library is accessible
- Check server upload limits

### Categories/tags not appearing
- First-time use: Categories/tags are created automatically
- Check WordPress > Categories/Tags to verify they were created
- Permissions: Ensure Application Password has `publish_posts` capability

## Related Features

- [Frontmatter Editor](frontmatter.md) - Edit metadata with ⌘I
- [Webhooks](webhooks.md) - Trigger actions after publishing
- [Plugins](plugins.md) - Enable/disable WordPress plugin

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Command Palette | ⌘K |
| Frontmatter Editor | ⌘I |

## Default Settings

Configure defaults in Settings > WordPress:

- **Default Status** - Draft, Publish, Pending, or Private
- **Default Categories** - Comma-separated category names
- **Default Author** - Author name for posts
- **Default Description** - Excerpt text if none in frontmatter

Frontmatter always overrides these defaults.

## Log Files

All WordPress API interactions are logged for debugging:

**Location:** `~/Library/Logs/tibok/tibok.log`

**Access:**
- Help > View Log File
- Help > Copy Log Path
- Help > Clear Log

Logs include:
- API requests and responses
- Authentication attempts
- Image upload details
- Error messages with full context

Use logs when reporting issues or debugging connection problems.
