# GitHub Repository Setup - tibok

> Repository structure, workflows, and configuration

## Repositories Overview

| Repository | URL | Visibility | Purpose |
|------------|-----|------------|---------|
| Main App | github.com/sturdy-barnacle/md-editor | Private | Proprietary app source |
| Plugin SDK | github.com/sturdy-barnacle/tibok-plugin-sdk | Public | Developer SDK (MIT) |
| Community Plugins | github.com/sturdy-barnacle/tibok-plugins | Public | Plugin gallery |

---

## Main App Repository

- **URL:** github.com/sturdy-barnacle/md-editor
- **Visibility:** Private (proprietary, never public)
- **Default Branch:** main

---

## Branch Strategy

### Branch Types

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready code | Protected |
| `develop` | Integration branch | Protected |
| `feature/*` | New features | None |
| `fix/*` | Bug fixes | None |
| `release/*` | Release preparation | None |

### Branch Naming

```
feature/MVP-1.1-app-scaffold
feature/BETA-3.2-git-status
fix/editor-crash-on-large-file
release/v0.1.0
```

### Protection Rules (main)

- [x] Require pull request before merging
- [x] Require status checks to pass
- [x] Require conversation resolution
- [ ] Require signed commits (optional)

---

## Directory Structure

```
md-editor/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── codeql.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── config.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
├── tibok/
│   ├── App/
│   ├── Features/
│   ├── Services/
│   ├── Models/
│   ├── Utilities/
│   └── Resources/
├── tibokTests/
│   ├── Fixtures/
│   └── ...
├── tibokUITests/
├── planning/
├── progress/
├── .gitignore
├── .swiftlint.yml
├── README.md
├── CLAUDE.md
├── ARCHITECTURE.md
├── PRD.md
├── LICENSE
└── tibok.xcodeproj/
```

---

## GitHub Actions Workflows

### CI Workflow (.github/workflows/ci.yml)

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode 16
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: .build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-

      - name: Build
        run: xcodebuild build -scheme tibok -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

      - name: Test
        run: xcodebuild test -scheme tibok -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

  lint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Install SwiftLint
        run: brew install swiftlint

      - name: Lint
        run: swiftlint lint --strict
```

### Release Workflow (.github/workflows/release.yml)

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode 16
        run: sudo xcode-select -s /Applications/Xcode_16.app

      - name: Import Certificates
        env:
          CERTIFICATE_BASE64: ${{ secrets.CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.CERTIFICATE_PASSWORD }}
        run: |
          # Import signing certificate
          echo $CERTIFICATE_BASE64 | base64 --decode > certificate.p12
          security create-keychain -p "" build.keychain
          security import certificate.p12 -k build.keychain -P $CERTIFICATE_PASSWORD -T /usr/bin/codesign
          security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain

      - name: Build Archive
        run: |
          xcodebuild archive \
            -scheme tibok \
            -archivePath build/tibok.xcarchive \
            -destination 'platform=macOS'

      - name: Export App
        run: |
          xcodebuild -exportArchive \
            -archivePath build/tibok.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ExportOptions.plist

      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          APPLE_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
          TEAM_ID: ${{ secrets.TEAM_ID }}
        run: |
          xcrun notarytool submit build/export/tibok.app.zip \
            --apple-id $APPLE_ID \
            --password $APPLE_PASSWORD \
            --team-id $TEAM_ID \
            --wait

      - name: Create DMG
        run: |
          hdiutil create -volname tibok -srcfolder build/export/tibok.app -ov -format UDZO build/tibok.dmg

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/tibok.dmg
          draft: true
```

---

## Issue Templates

### Bug Report (.github/ISSUE_TEMPLATE/bug_report.md)

```markdown
---
name: Bug Report
about: Report a bug in tibok
title: '[BUG] '
labels: bug
assignees: ''
---

## Description
A clear description of the bug.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- tibok version:
- macOS version:
- Mac model:

## Screenshots
If applicable, add screenshots.

## Additional Context
Any other relevant information.
```

### Feature Request (.github/ISSUE_TEMPLATE/feature_request.md)

```markdown
---
name: Feature Request
about: Suggest a new feature
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Problem
What problem does this solve?

## Proposed Solution
Describe the solution you'd like.

## Alternatives Considered
Any alternative solutions you've considered.

## Additional Context
Any other context or screenshots.
```

---

## Pull Request Template

### .github/PULL_REQUEST_TEMPLATE.md

```markdown
## Summary
Brief description of changes.

## Related Issues
Fixes #(issue number)

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed:
- [ ] Unit tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings

## Screenshots
If applicable, add screenshots of UI changes.
```

---

## Labels

| Label | Color | Description |
|-------|-------|-------------|
| `bug` | #d73a4a | Something isn't working |
| `enhancement` | #a2eeef | New feature or improvement |
| `documentation` | #0075ca | Documentation changes |
| `good first issue` | #7057ff | Good for newcomers |
| `help wanted` | #008672 | Extra attention needed |
| `priority: high` | #b60205 | High priority |
| `priority: medium` | #fbca04 | Medium priority |
| `priority: low` | #0e8a16 | Low priority |
| `epic: mvp` | #1d76db | MVP milestone |
| `epic: beta` | #5319e7 | Beta milestone |
| `epic: v1` | #006b75 | v1.0 milestone |

---

## Milestones

| Milestone | Due Date | Description |
|-----------|----------|-------------|
| MVP (v0.1) | TBD | Core editing experience |
| Beta (v0.5) | TBD | Git, commands, media |
| v1.0 | TBD | Full public release |

---

## CODEOWNERS

### .github/CODEOWNERS

```
# Default owners
* @sturdy-barnacle

# Specific areas
/tibok/Features/Editor/ @sturdy-barnacle
/tibok/Services/Git/ @sturdy-barnacle
/planning/ @sturdy-barnacle
```

---

## .gitignore

```gitignore
# Xcode
build/
DerivedData/
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/
*.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist

# Swift Package Manager
.build/
.swiftpm/
Package.resolved

# macOS
.DS_Store
*.swp
*~

# IDE
.idea/
.vscode/

# Secrets
*.p12
*.mobileprovision
.env
secrets.json

# Testing
coverage/
*.xcresult

# Archives
*.ipa
*.dSYM.zip
*.dSYM
```

---

## Secrets Required

| Secret | Purpose |
|--------|---------|
| `CERTIFICATE_BASE64` | Code signing certificate |
| `CERTIFICATE_PASSWORD` | Certificate password |
| `APPLE_ID` | Apple Developer account |
| `APPLE_APP_PASSWORD` | App-specific password |
| `TEAM_ID` | Apple Developer Team ID |

---

## Initial Setup Checklist

### Main App (md-editor)
- [ ] Create repository (done: github.com/sturdy-barnacle/md-editor)
- [ ] Set up branch protection rules
- [ ] Add issue templates
- [ ] Add PR template
- [ ] Configure GitHub Actions
- [ ] Set up labels and milestones
- [ ] Add CODEOWNERS
- [ ] Configure secrets (for CI/CD)
- [ ] Add proprietary LICENSE file

### Plugin SDK (tibok-plugin-sdk)
- [ ] Create repository: github.com/sturdy-barnacle/tibok-plugin-sdk
- [ ] Add MIT LICENSE
- [ ] Set up Package.swift for Swift Package Manager
- [ ] Create protocol definitions
- [ ] Add example plugins
- [ ] Add documentation (README, guides)
- [ ] Configure GitHub Actions (build, test)
- [ ] Set up GitHub Discussions for Q&A
- [ ] Create release workflow for versioned SDK

### Community Plugins (tibok-plugins)
- [ ] Create repository: github.com/sturdy-barnacle/tibok-plugins
- [ ] Add contribution guidelines (CONTRIBUTING.md)
- [ ] Create plugin submission template
- [ ] Set up automated plugin validation
- [ ] Configure GitHub Actions for PR checks

---

## Plugin SDK Repository Structure

```
tibok-plugin-sdk/
├── .github/
│   ├── workflows/
│   │   ├── build.yml
│   │   ├── test.yml
│   │   └── release.yml
│   └── ISSUE_TEMPLATE/
│       └── bug_report.md
├── Sources/
│   └── tibokPluginSDK/
│       ├── Protocols/
│       ├── Models/
│       └── Utilities/
├── Templates/
│   ├── ExporterTemplate/
│   ├── ThemeTemplate/
│   ├── AIProviderTemplate/
│   └── ActionTemplate/
├── Examples/
├── Tests/
├── Documentation/
├── Package.swift
├── README.md
├── LICENSE (MIT)
└── CONTRIBUTING.md
```

---

## Community Plugins Repository Structure

```
tibok-plugins/
├── .github/
│   ├── workflows/
│   │   └── validate-plugin.yml
│   ├── ISSUE_TEMPLATE/
│   │   └── plugin_submission.md
│   └── PULL_REQUEST_TEMPLATE.md
├── plugins/
│   ├── exporters/
│   │   ├── hugo-exporter/
│   │   └── notion-exporter/
│   ├── themes/
│   │   ├── nord-theme/
│   │   └── dracula-theme/
│   ├── ai-providers/
│   │   └── ollama-provider/
│   └── actions/
│       └── word-count/
├── registry.json          # Plugin index
├── README.md
├── CONTRIBUTING.md
└── LICENSE (MIT)
```

---

**Last Updated:** 2024-12-13
