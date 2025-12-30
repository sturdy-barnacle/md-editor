# Mac App Store Submission Guide for Tibok

This guide walks you through publishing Tibok to the Mac App Store.

## Prerequisites

Before you begin, ensure you have:
- ✅ Active Apple Developer Program membership ($99/year)
- ✅ Xcode installed
- ✅ Access to your Apple ID

## Step 1: Create Required Certificates

### 1.1 Mac App Distribution Certificate

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click the **+** button
3. Select **Mac App Distribution**
4. Follow the prompts to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** > Certificate Assistant > Request a Certificate from a Certificate Authority
   - Enter your email, select "Saved to disk"
5. Upload the CSR and download the certificate
6. Double-click to install it in your Keychain

### 1.2 Mac Installer Distribution Certificate

1. Return to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click the **+** button
3. Select **Mac Installer Distribution**
4. Use the same CSR or create a new one
5. Download and install the certificate

### 1.3 Verify Certificates

Run this command to verify both certificates are installed:

```bash
security find-identity -v -p codesigning
```

You should see:
- "Apple Distribution: Your Name (TEAM_ID)" or "3rd Party Mac Developer Application"
- "Mac Installer Distribution: Your Name (TEAM_ID)" or "3rd Party Mac Developer Installer"

## Step 2: Create App Store Connect Listing

### 2.1 Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** > **+** > **New App**
3. Fill in:
   - **Platform**: macOS
   - **Name**: Tibok
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Create new (com.kquinones.tibok)
   - **SKU**: tibok-macos (or any unique identifier)

### 2.2 App Information

Fill out the required fields:

**Category**:
- Primary: Developer Tools
- Secondary: Productivity

**App Privacy Policy URL**: (required)
- Create a simple privacy policy page or use a service like [Privacy Policy Generator](https://www.privacypolicygenerator.info/)

**Copyright**: © 2025 Kristina Quinones

### 2.3 Pricing and Availability

- **Price**: Free (or set your preferred price)
- **Availability**: All countries (or select specific regions)

### 2.4 App Store Description

Here's a suggested description:

```
Tibok - A Modern Markdown Editor for Developers

Tibok is a powerful, native macOS markdown editor designed specifically for developers who want a fast, distraction-free writing experience with integrated git workflow.

KEY FEATURES

📝 Fast Markdown Editing
• Real-time syntax highlighting
• Live preview with scroll sync
• Lightning-fast performance

🗂️ Smart Workspace Management
• Folder operations (create, rename, delete)
• Drag & drop file organization
• Multi-select for bulk operations
• Git-aware file moves that preserve history

🔀 Integrated Git Workflow
• Visual branch management and switching
• Side-by-side diff viewer with syntax highlighting
• Commit history browser
• Quick commit, push, and pull
• Comprehensive keyboard shortcuts

⌨️ Keyboard-First Design
• Extensive keyboard shortcuts for every operation
• Quick command palette
• Efficient navigation

💎 Native macOS Experience
• Optimized for Apple Silicon
• Follows macOS design guidelines
• App Sandbox for security
• Respects system appearance (Light/Dark mode)

PERFECT FOR

• Documentation writers
• Technical bloggers
• Developers maintaining README files
• Anyone who writes markdown in git repositories

Tibok combines the simplicity of a markdown editor with the power of integrated git operations, making it the perfect tool for developers who want to stay in their flow.
```

### 2.5 Screenshots (Required)

You need screenshots for Mac App Store:

**Required Sizes**:
- 1280 x 800 pixels (or 2560 x 1600 for Retina)
- At least 3 screenshots, up to 10

**How to Capture**:

1. Launch Tibok
2. Open a sample workspace with markdown files
3. Show key features:
   - Screenshot 1: Main editor with preview
   - Screenshot 2: Git panel with changes
   - Screenshot 3: Commit history view
   - Screenshot 4: Branch switcher
   - Screenshot 5: Multi-file selection

Use `Cmd + Shift + 4` to capture specific windows.

### 2.6 App Icon

The app already has an icon. Verify it meets requirements:
- 512 x 512 pixels minimum
- 1024 x 1024 pixels recommended
- PNG format
- No transparency

## Step 3: Create App-Specific Password

For uploading via command line, you need an app-specific password:

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in
3. Go to **Security** > **App-Specific Passwords**
4. Click **Generate Password**
5. Name it "Tibok App Store Upload"
6. Save the generated password securely (you can't view it again)

## Step 4: Build and Package

Run the build script:

```bash
cd /Users/kq/md-editor/tibok
./scripts/build-appstore.sh 1.0.3
```

This will:
1. Check for required certificates
2. Build the release binary
3. Sign with App Store entitlements
4. Create a .pkg installer
5. Output: `.build/appstore/Tibok-1.0.3.pkg`

## Step 5: Validate Package

Before uploading, validate the package:

```bash
xcrun altool --validate-app \
  -f .build/appstore/Tibok-1.0.3.pkg \
  -t macos \
  -u your-apple-id@email.com \
  -p your-app-specific-password
```

Replace:
- `your-apple-id@email.com` with your Apple ID
- `your-app-specific-password` with the password from Step 3

If validation succeeds, you'll see: "No errors validating archive"

## Step 6: Upload to App Store

### Option A: Command Line (Recommended)

```bash
xcrun altool --upload-app \
  -f .build/appstore/Tibok-1.0.3.pkg \
  -t macos \
  -u your-apple-id@email.com \
  -p your-app-specific-password
```

### Option B: Transporter App (GUI)

1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784) from Mac App Store
2. Open Transporter
3. Sign in with your Apple ID
4. Drag `.build/appstore/Tibok-1.0.3.pkg` into Transporter
5. Click **Deliver**

Upload typically takes 5-15 minutes depending on connection speed.

## Step 7: Submit for Review

After upload completes (you'll receive an email):

1. Return to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** > **Tibok**
3. Click the **+** next to **macOS App**
4. Select the uploaded build (1.0.3)
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

6. Add **Export Compliance Information**:
   - Does your app use encryption? **No** (unless you added custom crypto)
7. Click **Submit for Review**

## Step 8: Review Process

**Timeline**:
- Initial review typically takes 1-3 business days
- You'll receive emails about status changes

**Common Review Issues**:
- Missing screenshots
- Privacy policy missing or broken link
- App crashes on launch
- Functionality not clear

**If Rejected**:
1. Address the reviewer's feedback
2. Build new version with fixes
3. Upload again
4. Resubmit

## Step 9: After Approval

Once approved:
1. **Release**: Choose "Automatically release" or "Manually release"
2. **Monitor**: Check analytics in App Store Connect
3. **Updates**: For future versions, repeat Steps 4-7 with new version numbers

## Troubleshooting

### "Certificate not found"
- Verify certificates are installed: `security find-identity -v -p codesigning`
- Make sure you created **Mac App Distribution**, not **Mac Development**

### "Invalid signature"
- Ensure you're using the App Store entitlements (tibok-appstore.entitlements)
- Try cleaning: `rm -rf .build/appstore` and rebuild

### "Upload failed"
- Check your internet connection
- Verify app-specific password is correct
- Try using Transporter app instead

### "Binary is invalid"
- Ensure Info.plist has correct bundle ID (com.kquinones.tibok)
- Check version number is higher than any previously uploaded version
- Verify app is signed with App Store certificates

## App Store Optimization Tips

**Keyword Optimization**:
- Use relevant keywords in app name and subtitle
- Include: markdown, editor, git, developer, documentation

**Ratings & Reviews**:
- Prompt users to rate after positive experiences
- Respond to all reviews professionally

**Updates**:
- Release updates regularly (every 4-6 weeks)
- Highlight new features in "What's New"

## Additional Resources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [macOS App Distribution Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

**Need Help?**

If you encounter issues not covered here:
1. Check [Apple Developer Forums](https://developer.apple.com/forums/)
2. Contact Apple Developer Support
3. Review build logs in Console.app
