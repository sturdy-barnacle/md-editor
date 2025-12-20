# Epic: v1.0 - tibok

> Full release - AI, publishing, cloud sync, plugins

## Overview

The v1.0 release is the full-featured public release with AI assistance, Jekyll publishing, cloud sync, webhooks, and the plugin system. This establishes tibok as a complete markdown workflow solution.

**Product:** tibok (tibok.app)
**Target:** Public release on Mac App Store
**Prerequisite:** Beta (v0.5) complete
**Design Mockup:** `design_docs/tibok ui mockups/v1.0.jsx`

---

## Phases

### Phase 1: AI Integration (P0 - Critical)

AI-powered writing assistance.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-1.1 | AI service | Core AIService with provider abstraction | ⬜ Not Started |
| V1-1.2 | Claude provider | Claude API integration | ⬜ Not Started |
| V1-1.3 | API key management | Store/retrieve keys from Keychain | ⬜ Not Started |
| V1-1.4 | Streaming responses | Display AI output progressively | ⬜ Not Started |
| V1-1.5 | Writing suggestions | Grammar, style, clarity improvements | ⬜ Not Started |
| V1-1.6 | Text completion | Continue writing from cursor | ⬜ Not Started |
| V1-1.7 | Summarization | Generate document summary | ⬜ Not Started |
| V1-1.8 | Custom prompts | User-defined AI actions | ⬜ Not Started |
| V1-1.9 | Credit system | Track bundled AI credits usage | ⬜ Not Started |

**Exit Criteria:**
- [ ] AI suggestions work with streaming
- [ ] Both BYOK and bundled credits functional
- [ ] Graceful offline handling

### Phase 2: Jekyll Publishing (P0 - Critical)

Blog publishing workflow.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-2.1 | Frontmatter editor | GUI for YAML frontmatter | ⬜ Not Started |
| V1-2.2 | Jekyll formatter | Format post with proper filename | ⬜ Not Started |
| V1-2.3 | Asset handling | Copy images to Jekyll assets | ⬜ Not Started |
| V1-2.4 | Branch creation | Create feature branch for post | ⬜ Not Started |
| V1-2.5 | PR creation | Create GitHub PR via API | ⬜ Not Started |
| V1-2.6 | Publish workflow | One-click publish flow | ⬜ Not Started |

**Exit Criteria:**
- [ ] Can publish post to Jekyll blog
- [ ] PR created automatically
- [ ] Assets copied correctly

### Phase 3: Cloud Sync (P1 - Important)

iCloud Drive synchronization.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-3.1 | iCloud container | Set up ubiquity container | ⬜ Not Started |
| V1-3.2 | Sync detection | Detect iCloud Drive folders | ⬜ Not Started |
| V1-3.3 | Sync status | Per-file sync status indicator | ⬜ Not Started |
| V1-3.4 | Conflict handling | Detect and resolve conflicts | ⬜ Not Started |
| V1-3.5 | Offline mode | Queue changes when offline | ⬜ Not Started |

**Exit Criteria:**
- [ ] Files sync to iCloud automatically
- [ ] Conflict resolution works
- [ ] Offline editing seamless

### Phase 4: Webhooks (P1 - Important)

Custom automation triggers.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-4.1 | Webhook config | UI for creating webhooks | ⬜ Not Started |
| V1-4.2 | Trigger system | Fire on save/export/publish | ⬜ Not Started |
| V1-4.3 | Payload templates | Variable substitution in body | ⬜ Not Started |
| V1-4.4 | Authentication | Bearer tokens, API keys | ⬜ Not Started |
| V1-4.5 | Test webhook | Test button with response display | ⬜ Not Started |
| V1-4.6 | Webhook logs | History of webhook calls | ⬜ Not Started |

**Exit Criteria:**
- [ ] Webhooks fire on configured triggers
- [ ] Authentication headers work
- [ ] Logs show success/failure

### Phase 5: Plugin System (P1 - Important)

Extensibility infrastructure.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-5.1 | Plugin protocol | Base Plugin protocol definition | ⬜ Not Started |
| V1-5.2 | Plugin manager | Load, enable, disable plugins | ⬜ Not Started |
| V1-5.3 | Plugin sandbox | Restricted execution environment | ⬜ Not Started |
| V1-5.4 | Exporter plugins | ExporterPlugin protocol | ⬜ Not Started |
| V1-5.5 | Theme plugins | ThemePlugin protocol | ⬜ Not Started |
| V1-5.6 | AI provider plugins | AIProviderPlugin protocol | ⬜ Not Started |
| V1-5.7 | Action plugins | ActionPlugin protocol | ⬜ Not Started |
| V1-5.8 | Plugin gallery UI | Browse and install plugins | ⬜ Not Started |
| V1-5.9 | Built-in plugins | Bundle default plugins | ⬜ Not Started |
| V1-5.10 | Plugin SDK repo | Public SDK for developers | ⬜ Not Started |
| V1-5.11 | SDK documentation | Getting started, API reference | ⬜ Not Started |
| V1-5.12 | Example plugins | Sample exporter, theme, action | ⬜ Not Started |
| V1-5.13 | Plugin templates | Xcode templates for each type | ⬜ Not Started |
| V1-5.14 | Community repo | tibok-plugins for submissions | ⬜ Not Started |

**Exit Criteria:**
- [ ] Can install/uninstall plugins
- [ ] All plugin types functional
- [ ] Sandboxing enforced
- [ ] Plugin SDK published (github.com/sturdy-barnacle/tibok-plugin-sdk)
- [ ] SDK documentation complete
- [ ] At least 4 example plugins (one per type)
- [ ] Community plugins repo ready for submissions

### Phase 6: Pro Features & Licensing (P0 - Critical)

Freemium tier implementation.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-6.1 | Feature flags | Gate Pro features | ⬜ Not Started |
| V1-6.2 | License validation | Validate Pro purchases | ⬜ Not Started |
| V1-6.3 | StoreKit integration | In-app purchase setup | ⬜ Not Started |
| V1-6.4 | Upgrade prompts | Non-intrusive upgrade UI | ⬜ Not Started |
| V1-6.5 | Trial mode | Optional Pro trial period | ⬜ Not Started |

**Exit Criteria:**
- [ ] Free tier works without Pro
- [ ] Pro features gated correctly
- [ ] IAP flow functional

### Phase 7: Polish & Performance (P2 - Nice to Have)

Final optimizations and refinements.

| ID | Feature | Description | Status |
|----|---------|-------------|--------|
| V1-7.1 | Performance audit | Profile and optimize hot paths | ⬜ Not Started |
| V1-7.2 | Accessibility | VoiceOver, keyboard nav | ⬜ Not Started |
| V1-7.3 | Localization | Prepare for multiple languages | ⬜ Not Started |
| V1-7.4 | Onboarding | First-run experience | ⬜ Not Started |
| V1-7.5 | Help system | In-app help and shortcuts guide | ⬜ Not Started |

**Exit Criteria:**
- [ ] All performance targets met
- [ ] VoiceOver works throughout
- [ ] Onboarding complete

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| Anthropic Swift SDK | TBD | Claude API |
| StoreKit 2 | Built-in | In-app purchases |

---

## Acceptance Criteria (v1.0 Complete)

- [ ] All Beta features stable
- [ ] AI assistance fully functional
- [ ] Jekyll publishing works end-to-end
- [ ] iCloud sync reliable
- [ ] Webhooks functional
- [ ] Plugin system operational
- [ ] Plugin SDK public and documented
- [ ] Freemium model implemented
- [ ] Performance targets met
- [ ] Accessibility complete
- [ ] Ready for App Store submission

---

## Developer Ecosystem

### Repositories

| Repository | Status |
|------------|--------|
| sturdy-barnacle/md-editor | Private (proprietary) |
| sturdy-barnacle/tibok-plugin-sdk | Public (MIT) |
| sturdy-barnacle/tibok-plugins | Public |

### Developer Portal (tibok.app/developers)

- [ ] Landing page
- [ ] SDK download/install instructions
- [ ] Documentation hosting
- [ ] Plugin submission guidelines
- [ ] Developer forum/discussions

---

## Free vs Pro Feature Matrix

| Feature | Free | Pro |
|---------|------|-----|
| Editor | ✅ | ✅ |
| Live preview | ✅ | ✅ |
| Local storage | ✅ | ✅ |
| Export (MD, HTML) | ✅ | ✅ |
| Export (PDF) | ❌ | ✅ |
| Git integration | ❌ | ✅ |
| Jekyll publishing | ❌ | ✅ |
| AI assistance | ❌ | ✅ |
| Cloud sync | ❌ | ✅ |
| Webhooks | ❌ | ✅ |
| Themes | Basic | All |
| Plugins | ❌ | ✅ |

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| App Store rejection | High | Follow guidelines strictly, test on TestFlight |
| AI API costs | Medium | Implement rate limiting, clear credit usage |
| Plugin security | High | Thorough sandboxing, permission system |
| iCloud sync bugs | Medium | Extensive testing, conflict resolution |

---

## Notes

_Update this section as development progresses._

---

**Last Updated:** 2024-12-13
**Status:** 🔴 Not Started
