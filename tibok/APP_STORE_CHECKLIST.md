# App Store Submission Checklist

## ✅ Completed by Claude

- [x] Created App Store entitlements file
- [x] Created build script for App Store
- [x] Created comprehensive submission guide
- [x] Opened Apple Developer Certificates page

## 📋 Manual Steps Required

### Step 1: Create Mac App Distribution Certificate

**Status**: ⏳ IN PROGRESS (browser tab should be open)

On the Apple Developer Certificates page:

1. Click the **[+]** button in the top right
2. Select **"Mac App Distribution"**
3. Click **Continue**
4. You'll need to create a Certificate Signing Request (CSR):
   - I'll help you create this in the next step
5. Upload the CSR and download the certificate
6. Double-click the downloaded certificate to install it

---

### Step 2: Create Certificate Signing Request (CSR)

**Status**: ⏳ PENDING

1. Open **Keychain Access** (in /Applications/Utilities/)
2. Menu: **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Fill in:
   - **User Email Address**: Your email
   - **Common Name**: Your name
   - **CA Email Address**: Leave blank
   - **Request is**: Select **"Saved to disk"**
4. Click **Continue**
5. Save as `MacAppDistribution.certSigningRequest`
6. Go back to Step 1 and upload this CSR

---

### Step 3: Create Mac Installer Distribution Certificate

**Status**: ⏳ PENDING

Repeat Steps 1-2, but select **"Mac Installer Distribution"** instead:

1. Click **[+]** on certificates page
2. Select **"Mac Installer Distribution"**
3. Create another CSR or reuse the same one
4. Download and install the certificate

---

### Step 4: Verify Certificates Installed

**Status**: ⏳ PENDING

Run this command to verify both certificates are ready:

```bash
security find-identity -v -p codesigning
```

You should see:
- ✓ "Apple Distribution" or "3rd Party Mac Developer Application"
- ✓ "Mac Installer Distribution" or "3rd Party Mac Developer Installer"

---

### Step 5: Create App Store Connect Listing

**Status**: ⏳ PENDING

I'll open App Store Connect for you:

```bash
open "https://appstoreconnect.apple.com"
```

Then:

1. Click **My Apps**
2. Click **[+]** → **New App**
3. Fill in:
   - **Platform**: macOS
   - **Name**: Tibok
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select **"New"** and create `com.kquinones.tibok`
   - **SKU**: `tibok-macos`
4. Click **Create**

---

### Step 6: Fill App Information

**Status**: ⏳ PENDING

In the app listing:

1. **Category**:
   - Primary: Developer Tools
   - Secondary: Productivity

2. **Description**: (copy from APP_STORE_GUIDE.md, section 2.4)

3. **Keywords**: `markdown, editor, git, developer, documentation, writing, text`

4. **Support URL**: Your website or GitHub repo

5. **Privacy Policy URL**: Required - create a simple one at:
   - https://www.privacypolicygenerator.info/
   - Or create a GitHub page with your privacy policy

---

### Step 7: Create Screenshots

**Status**: ⏳ PENDING

Requirements:
- 1280 x 800 pixels (or 2560 x 1600 for Retina)
- At least 3 screenshots

I'll launch the app for you to capture screenshots:

```bash
open .build/release/tibok.app
```

**Recommended screenshots**:

1. **Main Editor**
   - Open a markdown file with preview visible
   - Show syntax highlighting
   - Press `Cmd + Shift + 4`, then space, click window

2. **Git Panel**
   - Show git panel with staged/unstaged files
   - Show branch selector
   - Capture with `Cmd + Shift + 4`

3. **Commit History**
   - Click history button in git panel
   - Show commit list with details
   - Capture the modal

4. **Multi-Select**
   - Select multiple files in sidebar
   - Show selection toolbar
   - Capture sidebar

5. **Diff Viewer** (optional)
   - Click diff button on a changed file
   - Show syntax-highlighted diff
   - Capture modal

Save all screenshots to: `/Users/kq/Desktop/AppStore_Screenshots/`

---

### Step 8: Create App-Specific Password

**Status**: ⏳ PENDING

1. I'll open Apple ID for you:
   ```bash
   open "https://appleid.apple.com"
   ```

2. Sign in
3. Go to **Security** section
4. Under **App-Specific Passwords**, click **Generate Password**
5. Name it: `Tibok App Store Upload`
6. **SAVE THE PASSWORD** - you can't view it again
7. Store it securely (you'll need it for upload)

---

### Step 9: Build App Store Package

**Status**: ⏳ PENDING

Once Steps 1-4 are complete (certificates installed), run:

```bash
cd /Users/kq/md-editor/tibok
./scripts/build-appstore.sh 1.0.3
```

This will create: `.build/appstore/Tibok-1.0.3.pkg`

---

### Step 10: Validate Package

**Status**: ⏳ PENDING

Before uploading, validate the package:

```bash
xcrun altool --validate-app \
  -f .build/appstore/Tibok-1.0.3.pkg \
  -t macos \
  -u YOUR_APPLE_ID@EMAIL.COM \
  -p YOUR_APP_SPECIFIC_PASSWORD
```

Replace with your actual Apple ID and app-specific password.

---

### Step 11: Upload to App Store

**Status**: ⏳ PENDING

**Option A: Command Line**

```bash
xcrun altool --upload-app \
  -f .build/appstore/Tibok-1.0.3.pkg \
  -t macos \
  -u YOUR_APPLE_ID@EMAIL.COM \
  -p YOUR_APP_SPECIFIC_PASSWORD
```

**Option B: Transporter App** (easier)

1. Download Transporter from Mac App Store
2. Sign in with Apple ID
3. Drag `.build/appstore/Tibok-1.0.3.pkg` to Transporter
4. Click **Deliver**

---

### Step 12: Submit for Review

**Status**: ⏳ PENDING

After upload completes (you'll get an email):

1. Go back to App Store Connect
2. Click your app → macOS App
3. Click **[+]** next to version
4. Select the uploaded build
5. Fill in **What's New in This Version**:

```
Initial Release

Tibok brings a modern, developer-focused markdown editing experience to macOS with integrated git workflow.

FEATURES:
• Fast markdown editing with live preview
• Complete workspace management (folders, drag & drop, multi-select)
• Integrated git operations (branch switching, diffs, commit history)
• Comprehensive keyboard shortcuts
• Native macOS design optimized for Apple Silicon

Perfect for documentation writers, technical bloggers, and developers maintaining markdown in git repositories.
```

6. Set **Export Compliance**:
   - "Does your app use encryption?" → **No**
7. Click **Submit for Review**

---

## Quick Reference Commands

### Check certificate status
```bash
security find-identity -v -p codesigning
```

### Build for App Store
```bash
./scripts/build-appstore.sh 1.0.3
```

### Validate package
```bash
xcrun altool --validate-app -f .build/appstore/Tibok-1.0.3.pkg -t macos -u YOUR_EMAIL -p APP_PASSWORD
```

### Upload package
```bash
xcrun altool --upload-app -f .build/appstore/Tibok-1.0.3.pkg -t macos -u YOUR_EMAIL -p APP_PASSWORD
```

---

## Estimated Timeline

- **Steps 1-4** (Certificates): 15-30 minutes
- **Steps 5-6** (App Store Connect): 30-60 minutes
- **Step 7** (Screenshots): 15-30 minutes
- **Step 8** (App Password): 5 minutes
- **Steps 9-11** (Build & Upload): 15-30 minutes
- **Step 12** (Submit): 10 minutes

**Total Time**: 2-3 hours
**Apple Review**: 1-3 business days

---

## Need Help?

Refer to `APP_STORE_GUIDE.md` for detailed instructions on each step.
