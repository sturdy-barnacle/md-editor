# Plugins

Tibok supports a plugin system that allows extending the editor with additional commands and features. Plugins can be enabled or disabled from Settings.

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

## Built-in Plugins

### Core Slash Commands
- **Identifier**: `com.tibok.core-slash-commands`
- **Provides**: 35+ slash commands for markdown formatting
- **Always recommended**: This plugin provides essential editing functionality

See [Slash Commands](slash-commands.md) for the full command reference.

## Plugin Information

Each plugin displays:
- **Name** and **description**
- **Version** number
- **Author** (if provided)
- **Icon** representing the plugin type

## Troubleshooting

### Slash commands not working?
1. Open Settings > Plugins
2. Verify "Core Slash Commands" is enabled
3. If disabled, toggle it on

### Plugin state not saving?
- Plugin preferences are stored in UserDefaults
- Check if you have write permissions to ~/Library/Preferences
