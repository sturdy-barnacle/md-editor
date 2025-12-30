# Xcode Cloud Setup Guide for Tibok

Xcode Cloud automates building, testing, and distributing your app to the App Store.

## Existing CI/CD Setup

✅ **You already have Xcode Cloud configured!**

Your existing setup:
- **App Store builds** trigger when you push to the `apple-store-distro` branch
- **Development builds** trigger when you push to the `development` branch
- Automatic code signing is already configured
- TestFlight distribution is enabled

## Quick Start: Trigger an App Store Build

**TL;DR - To release to the App Store:**

```bash
# Merge your changes to apple-store-distro
git checkout apple-store-distro
git pull origin apple-store-distro
git merge main  # or development
git push origin apple-store-distro

# Xcode Cloud will automatically build, sign, and upload to TestFlight
# Check App Store Connect for build status
```

That's it! The rest of this document explains the details.

## Xcode Cloud Workflow (`.xcode-ci.yml`)

Updated to match your existing setup:
- **App Store Release workflow**: Triggers on pushes to `apple-store-distro` branch
- **Development workflow**: Triggers on pushes to `development` branch
- Automatic code signing
- TestFlight distribution
- App Store submission

## Prerequisites

Before enabling Xcode Cloud:

1. ✅ Active Apple Developer Program membership
2. ✅ Git repository (you have this)
3. ✅ Xcode project (you have this)
4. ⏳ App Store Connect listing (create if not done yet)
5. ⏳ Xcode Cloud subscription (free tier available)

## Step-by-Step Setup

### Step 1: Enable Xcode Cloud in App Store Connect

1. Open [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Apps** → **Tibok** (or create the app if not done)
3. Click **Xcode Cloud** in the sidebar
4. Click **Get Started** or **Enable Xcode Cloud**
5. Choose your repository:
   - **Source Control Provider**: GitHub
   - **Repository**: sturdy-barnacle/md-editor
   - **Branch**: main
6. Grant access to your GitHub repository

### Step 2: Configure Xcode Cloud in Xcode (Alternative)

Or configure directly in Xcode:

1. Open `/Users/kq/md-editor/tibok/tibok.xcodeproj` in Xcode
2. Go to **Product** → **Xcode Cloud** → **Create Workflow**
3. Select **Archive - Mac**
4. Xcode will detect the `.xcode-ci.yml` file
5. Click **Enable Xcode Cloud**

### Step 3: Configure Code Signing

Xcode Cloud can manage signing automatically:

1. In Xcode, select the **tibok** target
2. Go to **Signing & Capabilities**
3. Check **Automatically manage signing**
4. Select **Team**: Kristina Quinones (F2PFRMGC9V)
5. For **Release** configuration:
   - Signing Certificate: **Apple Distribution**
   - Provisioning Profile: **Xcode Managed Profile**

### Step 4: Create App Store Connect API Key (Recommended)

For automated uploads:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Users and Access** → **Integrations** → **App Store Connect API**
3. Click **[+]** to create a new key
4. Name: `Xcode Cloud - Tibok`
5. Access: **Admin** (for full upload permissions)
6. Click **Generate**
7. **Download the API key** (.p8 file) - you can only download once
8. Save the:
   - **Key ID** (e.g., ABC123XYZ)
   - **Issuer ID** (e.g., 12345678-1234-1234-1234-123456789012)

### Step 5: Configure Xcode Cloud Settings

In App Store Connect → Xcode Cloud:

1. **Environment**:
   - Xcode Version: **Latest Release**
   - macOS Version: **Latest**

2. **Start Conditions**:
   - Branch changes: **main**
   - Tags: **v*.*.*`** (any version tag)
   - Pull requests: Optional

3. **Code Signing**:
   - Bundle ID: `com.kquinones.tibok`
   - Team: F2PFRMGC9V
   - Automatic signing: **Enabled**

4. **Post-Actions**:
   - ✅ Distribute to TestFlight
   - ✅ Notify by email

### Step 6: Push Workflow Configuration

The workflow is ready. Commit and push:

```bash
cd /Users/kq/md-editor/tibok

# Add the workflow file
git add .xcode-ci.yml XCODE_CLOUD_SETUP.md

# Commit
git commit -m "Add Xcode Cloud workflow configuration

- App Store release workflow triggered by version tags
- Development build workflow for testing
- Automatic code signing
- TestFlight distribution
- Email notifications"

# Push to main branch
git push origin development
git push origin main
```

### Step 7: Trigger an App Store Build

**To trigger an App Store build, merge your changes to the `apple-store-distro` branch:**

```bash
# Make sure you're on the branch with your changes (e.g., development or main)
git checkout main  # or development

# Merge to apple-store-distro
git checkout apple-store-distro
git pull origin apple-store-distro  # Get latest
git merge main  # Merge your changes
git push origin apple-store-distro  # Push to trigger build
```

Xcode Cloud will automatically:
1. Detect the push to `apple-store-distro`
2. Start a build
3. Archive the app
4. Sign with App Store certificate
5. Upload to TestFlight
6. Send notification when complete

**Alternative: Manual Trigger**

1. Go to App Store Connect → Xcode Cloud
2. Click **Start Build**
3. Select branch: **apple-store-distro**
4. Click **Start**

### Step 8: Monitor Build Progress

1. In App Store Connect:
   - Go to **Xcode Cloud** → **Builds**
   - Watch build progress in real-time
   - View logs if build fails

2. In Xcode:
   - Go to **Cloud** tab in Report Navigator
   - See build status and logs

3. Email notifications:
   - You'll receive emails for build success/failure

### Step 9: Submit to App Store

Once build completes and uploads to TestFlight:

1. Go to **App Store Connect** → **Tibok**
2. Click **App Store** tab
3. Click **[+]** next to macOS
4. Select the build from TestFlight
5. Fill in metadata (if not done):
   - What's New
   - Screenshots
   - Description
   - Keywords
6. Click **Submit for Review**

## Xcode Cloud Workflow Explanation

### App Store Release Workflow

Triggered by: Pushes to `apple-store-distro` branch

Steps:
1. ✅ Clean build
2. ✅ Build Release configuration for arm64
3. ✅ Archive for App Store
4. ✅ Sign with Apple Distribution certificate
5. ✅ Upload to TestFlight
6. ✅ Email notification

### Development Workflow

Triggered by: Pushes to `development` branch

Steps:
1. ✅ Build Debug configuration
2. ✅ Verify compilation succeeds
3. ✅ Email notification

## Advantages of Xcode Cloud

✨ **Automated Builds**
- No need to build locally
- Consistent environment every time
- Fresh clone from git ensures reproducibility

✨ **Automatic Code Signing**
- No need to manage certificates manually
- Xcode Cloud handles provisioning profiles
- Works seamlessly with App Store Connect

✨ **TestFlight Integration**
- Automatic upload after successful build
- Distribute to beta testers immediately
- Collect feedback before App Store release

✨ **Version Control**
- Triggered by git tags
- Clear mapping: git tag → build → release
- Easy to track which commit is in production

## Pricing

**Free Tier** (included with Apple Developer Program):
- 25 compute hours per month
- Each build takes ~10-20 minutes
- Enough for ~75-150 builds per month

**Paid Tiers** (if you need more):
- Additional hours available
- Check App Store Connect for pricing

## Troubleshooting

### Build Fails with "Signing Error"

1. Verify team ID in `.xcode-ci.yml` matches your Team ID (F2PFRMGC9V)
2. Ensure "Automatically manage signing" is enabled in Xcode
3. Check Bundle ID is `com.kquinones.tibok`

### Build Succeeds but Doesn't Upload

1. Verify App Store Connect API key is configured
2. Check export method is `app-store` in workflow
3. Ensure app listing exists in App Store Connect

### Build Not Triggered

1. Verify `.xcode-ci.yml` is in repository root
2. Check tag format matches pattern: `v1.0.3` not `1.0.3`
3. Ensure Xcode Cloud is enabled in App Store Connect

### Email Notifications Not Working

1. Check notification settings in App Store Connect
2. Verify email address in Apple ID
3. Check spam folder

## Comparison: Manual vs Xcode Cloud

| Step | Manual Process | Xcode Cloud |
|------|---------------|-------------|
| **Build** | Run script locally | Automatic on tag |
| **Code Signing** | Manage certificates | Automatic |
| **Upload** | Command line/Transporter | Automatic |
| **TestFlight** | Manual distribution | Automatic |
| **Submit** | Manual in ASC | Manual in ASC |
| **Time** | ~30 minutes | ~15 minutes |
| **Reproducibility** | Depends on local env | Guaranteed |

## Quick Reference: Common Commands

### Trigger App Store Build

```bash
git checkout apple-store-distro
git pull origin apple-store-distro
git merge main  # Merge your latest changes
git push origin apple-store-distro  # Triggers build
```

### Check Build Status

- **App Store Connect**: https://appstoreconnect.apple.com → Xcode Cloud → Builds
- **Email**: You'll receive notifications for success/failure

### Submit to App Store (After Build Completes)

1. Go to App Store Connect → Your App → App Store tab
2. Click **[+]** next to macOS version
3. Select build from TestFlight
4. Fill in "What's New" and metadata
5. Click **Submit for Review**

## Next Steps After Setup

1. **Merge to apple-store-distro**: Follow Quick Reference above
2. **Monitor build**: Check App Store Connect
3. **Test on TestFlight**: Download from TestFlight and verify
4. **Submit for review**: When ready, submit from App Store Connect

## Resources

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Workflow Configuration Reference](https://developer.apple.com/documentation/xcode/configuring-your-first-xcode-cloud-workflow)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

**Questions?**

- Check build logs in App Store Connect
- Review Xcode Cloud documentation
- Contact Apple Developer Support
