# Plugins

tibok supports a plugin system that allows extending the editor with additional commands and features. Plugins can be enabled or disabled from Settings.

## Plugin Types

tibok discovers plugins from two locations:

### 1. Built-in Plugins (Included with tibok)
- Location: `~/Library/Application Support/tibok/Plugins/BuiltIn/`
- Updated with tibok releases
- Always available
- Examples: Core Slash Commands, Frontmatter, WordPress Export

### 2. Community Plugins (User-installed)
- Location: `~/Library/Application Support/tibok/Plugins/ThirdParty/`
- Install community-created plugins here
- Plugins shared by other developers
- Browse the [Plugin Registry](../../PLUGIN_REGISTRY.md) to find plugins

## Managing Plugins

1. Open **Settings** (Cmd+,)
2. Click the **Plugins** tab
3. Toggle plugins on/off using the switch

When you disable a plugin:
- Its slash commands are immediately removed
- Its command palette commands are removed
- Changes take effect instantly (no restart required)

When you enable a plugin:
- Its commands become available immediately
- State persists across app restarts

## Installing Plugins

### Using the Install Button (Recommended)

1. Open **Settings** (Cmd+,)
2. Click the **Plugins** tab
3. Click **"Install Plugin..."** button
4. Select a plugin folder or ZIP file
5. The plugin will be automatically installed and discovered
6. Toggle the plugin on/off as needed

**Supported formats:**
- Plugin folder (containing `manifest.json`)
- ZIP file containing a plugin folder

The installer will:
- Extract ZIP files automatically
- Validate plugin structure
- Handle plugin updates (replaces existing plugins with same identifier)
- Show success/error notifications

### Manual Installation

If you prefer to install manually:

**From ZIP file:**
1. Download a plugin (usually a .zip file)
2. Extract the plugin folder
3. Move to `~/Library/Application Support/tibok/Plugins/ThirdParty/`
4. Restart tibok
5. Go to Settings > Plugins and enable the plugin

**From folder:**
1. Open Finder
2. Press Cmd+Shift+G (Go to folder)
3. Paste: `~/Library/Application Support/tibok/Plugins/ThirdParty/`
4. Drag plugin folders here
5. Restart tibok

### Removing Plugins

1. Go to Settings > Plugins
2. Disable the plugin
3. Open Finder to plugin folder (Cmd+Shift+G)
4. Navigate to `~/Library/Application Support/tibok/Plugins/ThirdParty/`
5. Delete the plugin folder
6. Restart tibok

## Built-in Plugins

### Core Slash Commands
- **Identifier**: `com.tibok.core-slash-commands`
- **Provides**: 35+ slash commands for markdown formatting
- **Always recommended**: This plugin provides essential editing functionality

See [Slash Commands](slash-commands.md) for the full command reference.

### Frontmatter Plugin
- **Identifier**: `com.tibok.frontmatter`
- **Description**: Jekyll/Hugo/WordPress metadata editing
- **Provides**:
  - **⌘I** keyboard shortcut to open frontmatter inspector
  - Slash commands for frontmatter management:
    - `/frontmatter` - Insert YAML frontmatter template
    - `/toml` - Insert TOML frontmatter template
    - `/draft` - Toggle draft status
    - `/publish` - Publish document (set draft: false)
  - Visual editor for metadata fields (title, date, tags, categories, etc.)

See [Frontmatter](frontmatter.md) for full metadata editing documentation.

### WordPress Export Plugin
- **Identifier**: `com.tibok.wordpress-export`
- **Description**: Publish markdown to WordPress via REST API
- **Provides**:
  - Command Palette: "Publish to WordPress"
  - Direct publishing to WordPress.com or self-hosted sites
  - Automatic image upload to Media Library
  - Category/tag auto-creation
  - Frontmatter support for post metadata
- **Requirements**:
  - WordPress 5.6+ or WordPress.com site
  - Application Password for authentication
- **Settings**: Configure in Settings > WordPress

See [WordPress Publishing](wordpress-publishing.md) for full publishing documentation.

## Plugin Information

Each plugin displays:
- **Name** and **description**
- **Version** number
- **Author** (if provided)
- **Icon** representing the plugin type

## Third-Party Plugin Status

**Current Status:** Third-party plugins can be installed and discovered, but **dynamic loading is not yet implemented**. This means:

- ✅ Third-party plugins can be installed via the "Install Plugin..." button
- ✅ Installed plugins appear in the Settings > Plugins list
- ❌ Third-party plugins cannot be enabled/disabled or executed yet
- ❌ Third-party plugins will show as "Installed - Not yet supported"

**Built-in plugins** (Core Slash Commands, Frontmatter, WordPress Export) work fully and can be toggled on/off.

Dynamic plugin loading will be implemented in a future update, allowing third-party plugins to be fully functional.

## Troubleshooting

### Slash commands not working?
1. Open Settings > Plugins
2. Verify "Core Slash Commands" is enabled
3. If disabled, toggle it on

### Plugin state not saving?
- Plugin preferences are stored in UserDefaults
- Check if you have write permissions to ~/Library/Preferences
