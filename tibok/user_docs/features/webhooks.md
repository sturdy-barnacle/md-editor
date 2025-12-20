# Webhooks

Webhooks allow tibok to send HTTP requests to external services when events occur, such as saving a document or pushing to Git. This is useful for triggering build pipelines, notifying services, or integrating with automation tools.

## Accessing Webhooks

Open Settings (Cmd+,) and navigate to the **Webhooks** tab.

## Creating a Webhook

1. Click **Add Webhook**
2. Fill in the webhook details:
   - **Name**: A descriptive name for the webhook
   - **URL**: The endpoint to send requests to
   - **Method**: HTTP method (GET, POST, PUT, DELETE)
3. Select which **Events** should trigger this webhook
4. Customize **Headers** if needed (Content-Type: application/json is set by default)
5. Edit the **Payload Template** to customize the request body
6. Click **Save**

## Events

| Event | Description |
|-------|-------------|
| Document Save | Triggered when a document is saved |
| Document Export | Triggered when exporting to PDF, HTML, etc. |
| Git Push | Triggered after pushing to a remote repository |

You can select multiple events for a single webhook.

## Payload Variables

Use these variables in your payload template. They will be replaced with actual values when the webhook fires:

| Variable | Description |
|----------|-------------|
| `{{event}}` | The event that triggered the webhook (e.g., `document.save`) |
| `{{filename}}` | Name of the document file |
| `{{title}}` | Document title (from frontmatter, or filename if not set) |
| `{{path}}` | Full file path |
| `{{timestamp}}` | ISO 8601 timestamp of when the event occurred |
| `{{content}}` | Document content (JSON-escaped) |

### Default Payload Template

```json
{
  "event": "{{event}}",
  "filename": "{{filename}}",
  "title": "{{title}}",
  "path": "{{path}}",
  "timestamp": "{{timestamp}}"
}
```

## Testing Webhooks

Before relying on a webhook, test it:

1. Open the webhook editor
2. Click **Send Test Request**
3. Check the result indicator for success/failure
4. The test uses sample data (test-document.md)

## Managing Webhooks

### Enable/Disable

Toggle the switch next to any webhook to enable or disable it without deleting the configuration.

### Edit

Click the pencil icon to modify an existing webhook.

### Delete

Swipe left on a webhook row or use the delete option to remove it.

## Use Cases

### Trigger a Jekyll/Hugo Build

Send a POST request to your CI/CD service when you save a document:

```json
{
  "event": "{{event}}",
  "repository": "my-blog",
  "file": "{{filename}}",
  "timestamp": "{{timestamp}}"
}
```

### Notify Slack

Post to a Slack webhook when content is updated:

```json
{
  "text": "Document updated: {{title}} ({{filename}})"
}
```

### Log to a Service

Send document metadata to a logging service for analytics.

## Troubleshooting

### Webhook not firing

1. Check that the webhook is enabled (toggle is on)
2. Verify the correct events are selected
3. Make sure the URL is correct and accessible

### Request failing

1. Use the **Test** button to check connectivity
2. Verify headers are correct for your endpoint
3. Check that the payload template is valid JSON
4. Review the HTTP status code in the test result

### Timeout errors

Webhooks have a 30-second timeout. If your endpoint is slow, consider:
- Using an async endpoint that returns immediately
- Optimizing the receiving service
