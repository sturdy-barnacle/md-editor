# App Icon & Branding Guidelines

> Visual identity for tibok

## App Name

**Primary:** tibok
**Styled:** tibok (always lowercase t)
**Bundle ID:** app.tibok.editor
**Website:** tibok.app
**Marketing Name:** tibok - Markdown for Mac

---

## App Icon

> **Design Source:** `design_docs/tibok icons logos.jsx`

### Final Design

The tibok icon uses the `#t` combination, emphasizing both markdown syntax and the tibok brand.

### Icon Variants

| Variant | Design | Usage |
|---------|--------|-------|
| **Primary** | `#` (muted) + `t` (bold) | App icon, dock, marketing |
| **One Color** | `#t` (solid) | Monochrome contexts, favicons |
| **Accent (Open)** | `<t>` | Documentation, alternate branding |
| **Accent (Close)** | `</t>` | Documentation, alternate branding |

### Technical Specifications

| Property | Value |
|----------|-------|
| Font | Open Sans SemiBold (600) |
| ViewBox | 0 0 512 512 |
| Corner Radius | 113px (~22%, macOS Big Sur style) |
| Shadow | drop-shadow(0 4px 12px rgba(0,0,0,0.1)) |

### Icon Sizes

| Size | Usage |
|------|-------|
| 16x16 | Finder list view, menu bar |
| 24x24 | Toolbar icons |
| 32x32 | Finder list view @2x |
| 48x48 | Icon with logotype |
| 64x64 | Finder |
| 96x96 | Large previews |
| 128x128 | Finder @2x |
| 256x256 | Finder @2x |
| 512x512 | App Store |
| 1024x1024 | App Store @2x |

### Color Specifications

**Light Mode:**

| Element | Color | Hex |
|---------|-------|-----|
| Background | Warm White | #FAFAFA |
| Primary Text (`t`) | Charcoal | #333333 |
| Muted Text (`#`) | Light Gray | #BBBBBB |

**Dark Mode:**

| Element | Color | Hex |
|---------|-------|-----|
| Background | Dark Gray | #2D2D2D |
| Primary Text (`t`) | White | #FFFFFF |
| Muted Text (`#`) | Medium Gray | #666666 |

### Icon Construction (Primary Variant)

```svg
<svg viewBox="0 0 512 512">
  <rect width="512" height="512" rx="113" fill="#FAFAFA"/>
  <g font-family="'Open Sans', sans-serif" font-weight="600">
    <text x="100" y="352" font-size="240" fill="#BBBBBB">#</text>
    <text x="280" y="352" font-size="240" fill="#333333">t</text>
  </g>
</svg>
```

### Icon with Logotype

The icon pairs with the "tibok" wordmark for full branding:
- Icon size: 48x48
- Logotype: Open Sans SemiBold (600), 24px
- Gap: 12px
- Style: All lowercase

---

## Typography

### Primary Font: Open Sans

**Source:** https://fonts.google.com/specimen/Open+Sans
**License:** Open Font License (OFL)

Open Sans is the primary typeface for tibok across all platforms - app UI, marketing, documentation, and web properties.

### Font Weights Used

| Weight | Name | Usage |
|--------|------|-------|
| 300 | Light | Large display text, hero sections |
| 400 | Regular | Body text, UI labels |
| 500 | Medium | Subheadings, emphasis |
| 600 | SemiBold | Headings, buttons |
| 700 | Bold | Primary headings, strong emphasis |

### Logotype

**Font:** Open Sans SemiBold
**Tracking:** -10 (slightly tight)
**Style:** All lowercase

```
tibok  ← Always lowercase
```

### Wordmark Usage

- Always use lowercase "t" in tibok
- Never capitalize: ~~Tibok~~, ~~TIBOK~~
- Acceptable: "tibok app", "tibok editor"

### Marketing & Web Typography

| Usage | Font | Weight | Size |
|-------|------|--------|------|
| Headlines | Open Sans | Bold (700) | 48-72px |
| Subheads | Open Sans | SemiBold (600) | 24-32px |
| Body | Open Sans | Regular (400) | 16-18px |
| Code | SF Mono / Fira Code | Regular | 14-16px |

### App UI Typography

| Element | Font | Weight | Size |
|---------|------|--------|------|
| Navigation | Open Sans | SemiBold | 13px |
| Labels | Open Sans | Regular | 13px |
| Body text | Open Sans | Regular | 14px |
| Buttons | Open Sans | SemiBold | 13px |
| Captions | Open Sans | Regular | 11px |

### Font Loading (Web)

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

### Font Bundling (App)

Bundle Open Sans in the app for offline use:
- Include .ttf or .otf files in Resources/Fonts/
- Register in Info.plist under "Fonts provided by application"

---

## Color System

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Ink | #1A1A1A | Primary text, headings |
| Paper | #FFFFFF | Backgrounds |
| Accent | #007AFF | Links, buttons, focus |

### Secondary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Stone | #6B6B6B | Secondary text |
| Mist | #F5F5F5 | Secondary backgrounds |
| Border | #E5E5E5 | Dividers, borders |

### Semantic Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success | #34C759 | Save complete, sync done |
| Warning | #FF9500 | Conflicts, attention |
| Error | #FF3B30 | Errors, delete |
| Info | #5AC8FA | Tips, information |

---

## Document Icon

For .md files associated with the app:

```
┌──────────┐
│░░░░░░░░░░│
│──────────│
│ # ────── │
│   ────── │
│   ────   │
└──────────┘
```

Simpler than app icon, uses same color palette.

---

## Marketing Assets

### Screenshots (App Store)

1. **Editor + Preview** - Split view showing markdown and rendered output
2. **Command Palette** - Quick actions in action
3. **Git Integration** - Commit/push workflow
4. **AI Suggestions** - Writing assistance feature
5. **Export Options** - PDF/HTML export

### App Store Description

**Subtitle:** The markdown editor for Mac

**Keywords:** markdown, editor, writing, preview, git, jekyll, blog, notes, documentation, tibok

**Promotional Text:**
> Write in markdown, publish anywhere. tibok is a native Mac app built for writers who love keyboard shortcuts, live preview, and seamless publishing workflows.

---

## Voice & Tone

### Principles

1. **Clear** - Say what you mean, simply
2. **Helpful** - Guide without condescending
3. **Confident** - Know the product, own the voice
4. **Warm** - Friendly but professional

### Examples

**Good:**
- "Your document is saved."
- "Couldn't connect to GitHub. Check your credentials."
- "Preview updates as you type."

**Avoid:**
- "Awesome! Your document has been successfully saved to disk!"
- "Oops! Something went wrong with the GitHub thingy."
- "Our revolutionary live preview technology..."

---

## Domain & URLs

| Property | Value |
|----------|-------|
| Primary domain | tibok.app |
| App Store | apps.apple.com/app/tibok |
| Support | tibok.app/support |
| Documentation | tibok.app/docs |
| Developer Portal | tibok.app/developers |
| Plugin Gallery | tibok.app/plugins |

## GitHub Repositories

| Repository | Purpose | Visibility |
|------------|---------|------------|
| sturdy-barnacle/md-editor | Main app source | Private (proprietary) |
| sturdy-barnacle/tibok-plugin-sdk | Plugin SDK for developers | Public (MIT) |
| sturdy-barnacle/tibok-plugins | Official & community plugins | Public |

---

## File Naming

| Asset Type | Convention |
|------------|------------|
| App icons | `tibok-icon-{size}.png` |
| Screenshots | `tibok-screenshot-{feature}-{number}.png` |
| Marketing | `tibok-{asset}-{variant}.png` |

---

## Notes

_Update branding assets and guidelines as design evolves._

---

**Last Updated:** 2024-12-13
