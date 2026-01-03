# Build Your First Tibok Plugin

**Time needed:** 15-20 minutes
**Skill level:** Beginner (basic JavaScript knowledge helpful)

In this guide, you'll create a plugin that adds useful writing tools to Tibok. By the end, you'll have slash commands, text transformations, and a word counter!

---

## What You'll Build

Your plugin will add:
- `/today` - Insert today's date
- `/note` - Insert a callout box
- **Word Count** command in Cmd+K
- **Transform to UPPERCASE** for selected text
- And more!

---

## Step 1: Create Your Plugin Folder

Plugins live in a special folder on your Mac. Open Terminal and run:

```bash
mkdir -p ~/Library/Application\ Support/tibok/Plugins/ThirdParty/com.yourname.writing-tools
```

**What's happening:** This creates a folder for your plugin. The name (`com.yourname.writing-tools`) is your plugin's unique ID — like a username, but for plugins.

> 💡 **Tip:** Replace `yourname` with your actual name or username!

---

## Step 2: Create the Manifest File

Every plugin needs a `manifest.json` file. This tells Tibok what your plugin is called and what it needs to work.

Create the file:

```bash
cd ~/Library/Application\ Support/tibok/Plugins/ThirdParty/com.yourname.writing-tools
```

Now create `manifest.json` with this content:

```json
{
  "identifier": "com.yourname.writing-tools",
  "name": "Writing Tools",
  "version": "1.0.0",
  "description": "Helpful tools for writers",
  "icon": "pencil.and.outline",
  "author": "Your Name",
  "plugin_type": "script",
  "permissions": [
    "slash-commands",
    "insert-text",
    "read-current-document",
    "read-selection"
  ],
  "entry_point": {
    "script": "main.js"
  }
}
```

**What each part means:**

| Field | What It Does |
|-------|--------------|
| `identifier` | Unique ID for your plugin (use reverse domain style) |
| `name` | What users see in Settings |
| `version` | Your plugin's version number |
| `description` | A short explanation of what it does |
| `icon` | An SF Symbol name (find icons at [SF Symbols](https://developer.apple.com/sf-symbols/)) |
| `permissions` | What your plugin is allowed to do |
| `entry_point` | Which file contains your code |

---

## Step 3: Create Your Plugin Code

Now for the fun part! Create `main.js` in the same folder:

```javascript
// My first Tibok plugin!
tibok.log.info("Writing Tools plugin is loading...");

// === SLASH COMMANDS ===
// These appear when you type "/" in the editor

// A simple slash command that inserts text
tibok.slashCommands.register({
    name: "today",
    description: "Insert today's date",
    icon: "calendar",
    execute: function() {
        var today = new Date();
        var formatted = today.toLocaleDateString("en-US", {
            weekday: "long",
            year: "numeric",
            month: "long",
            day: "numeric"
        });
        tibok.editor.insertText(formatted);
    }
});

// A slash command with static text
tibok.slashCommands.register({
    name: "note",
    description: "Insert a note callout",
    icon: "note.text",
    insert: "> **Note:** Your note here\n"
});

tibok.log.info("Writing Tools loaded! Try typing /today");
```

**What's happening:**
- `tibok.log.info()` prints a message (you can see it in Console.app)
- `tibok.slashCommands.register()` adds a new slash command
- `execute` runs code when the command is used
- `insert` just pastes static text

---

## Step 4: Test Your Plugin

1. **Open Tibok** (or restart it if already open)
2. Go to **Settings → Plugins**
3. Find "Writing Tools" in the list
4. **Enable it** with the toggle switch
5. You'll see a permission approval dialog — click **Allow**

Now try it:
- Open a document
- Type `/today` and press Enter
- Your date should appear! 🎉

---

## Step 5: Add More Features

Let's add a command palette command. These appear when you press `Cmd+K`.

Add this to your `main.js`:

```javascript
// === COMMAND PALETTE ===
// These appear when you press Cmd+K

tibok.commands.register({
    id: "word-count",
    title: "Word Count",
    subtitle: "Count words in document",
    icon: "number",
    action: function() {
        // Get all the text in the document
        var content = tibok.editor.getContent();

        // Count words
        var words = content.trim().split(/\s+/);
        var count = words.filter(function(w) {
            return w.length > 0;
        }).length;

        // Insert the count
        tibok.editor.insertText("📊 Word count: " + count);
    }
});
```

**Restart Tibok**, then:
1. Press `Cmd+K`
2. Type "word"
3. Select "Word Count"
4. The word count appears in your document!

---

## Step 6: Work with Selected Text

Let's add a command that transforms selected text to UPPERCASE:

```javascript
tibok.commands.register({
    id: "uppercase",
    title: "UPPERCASE",
    subtitle: "Transform selection to uppercase",
    icon: "textformat.size.larger",
    action: function() {
        var selected = tibok.editor.getSelectedText();

        if (selected.length > 0) {
            tibok.editor.replaceSelection(selected.toUpperCase());
        } else {
            tibok.log.warn("No text selected!");
        }
    }
});
```

**Try it:**
1. Select some text in your document
2. Press `Cmd+K`
3. Choose "UPPERCASE"
4. Your text is now UPPERCASE!

---

## The Complete Plugin

Here's everything together. Replace your `main.js` with this:

```javascript
// Writing Tools Plugin for Tibok
tibok.log.info("Writing Tools is loading...");

// ============ SLASH COMMANDS ============

tibok.slashCommands.register({
    name: "today",
    description: "Insert today's date",
    icon: "calendar",
    execute: function() {
        var today = new Date();
        tibok.editor.insertText(today.toLocaleDateString("en-US", {
            weekday: "long", year: "numeric", month: "long", day: "numeric"
        }));
    }
});

tibok.slashCommands.register({
    name: "note",
    description: "Insert a note callout",
    icon: "note.text",
    insert: "> **Note:** Your note here\n"
});

tibok.slashCommands.register({
    name: "warning",
    description: "Insert a warning callout",
    icon: "exclamationmark.triangle",
    insert: "> ⚠️ **Warning:** Your warning here\n"
});

// ============ COMMAND PALETTE ============

tibok.commands.register({
    id: "word-count",
    title: "Word Count",
    subtitle: "Count words in document",
    icon: "number",
    action: function() {
        var content = tibok.editor.getContent();
        var words = content.trim().split(/\s+/).filter(function(w) {
            return w.length > 0;
        });
        tibok.editor.insertText("📊 " + words.length + " words");
    }
});

tibok.commands.register({
    id: "uppercase",
    title: "UPPERCASE",
    subtitle: "Transform selection to uppercase",
    icon: "textformat.size.larger",
    action: function() {
        var selected = tibok.editor.getSelectedText();
        if (selected) {
            tibok.editor.replaceSelection(selected.toUpperCase());
        }
    }
});

tibok.commands.register({
    id: "lowercase",
    title: "lowercase",
    subtitle: "Transform selection to lowercase",
    icon: "textformat.size.smaller",
    action: function() {
        var selected = tibok.editor.getSelectedText();
        if (selected) {
            tibok.editor.replaceSelection(selected.toLowerCase());
        }
    }
});

tibok.log.info("Writing Tools loaded!");
```

---

## API Reference (Cheat Sheet)

### Slash Commands

```javascript
tibok.slashCommands.register({
    name: "commandname",      // What user types after /
    description: "...",       // Shown in the menu
    icon: "sf.symbol.name",   // SF Symbol icon
    insert: "static text",    // OR use execute for dynamic
    execute: function() {
        // Your code here
    }
});
```

### Command Palette

```javascript
tibok.commands.register({
    id: "unique-id",
    title: "Command Name",
    subtitle: "Description",
    icon: "sf.symbol.name",
    action: function() {
        // Your code here
    }
});
```

### Editor API

```javascript
// Insert text at cursor
tibok.editor.insertText("Hello!");

// Get selected text
var selected = tibok.editor.getSelectedText();

// Replace selected text
tibok.editor.replaceSelection("New text");

// Get entire document
var content = tibok.editor.getContent();

// Get cursor position
var pos = tibok.editor.getCursorPosition();
```

### Logging

```javascript
tibok.log.info("Normal message");
tibok.log.warn("Warning message");
tibok.log.error("Error message");
```

---

## Permissions Explained

| Permission | What It Allows |
|------------|----------------|
| `slash-commands` | Register `/commands` |
| `command-palette` | Add Cmd+K commands |
| `insert-text` | Insert text at cursor |
| `read-current-document` | Read document content |
| `read-selection` | Access selected text |
| `read-document-metadata` | Read filename, path, etc. |

Only request what you need! Users see these permissions before installing.

---

## Troubleshooting

**Plugin doesn't show up?**
- Make sure the folder name matches the `identifier` in manifest.json
- Check that manifest.json is valid JSON (no trailing commas!)
- Restart Tibok

**Commands don't work?**
- Open Console.app and filter by "tibok" to see error messages
- Check for JavaScript syntax errors in main.js
- Make sure you have the right permissions in manifest.json

**Need to reload changes?**
- Disable and re-enable the plugin in Settings
- Or restart Tibok

---

## What's Next?

**Ideas for your plugin:**
- Add more date formats (`/date-iso`, `/date-short`)
- Create templates for common documents
- Build a Pomodoro timer
- Make a random quote inserter

**Ready to share?**
When your plugin is ready, you can submit it to the Tibok Plugin Marketplace for others to discover and install!

---

## Full Example

Check out the complete "Writing Tools" plugin in the examples folder:
- `examples/plugins/writing-tools/manifest.json`
- `examples/plugins/writing-tools/main.js`

Happy coding! 🚀
