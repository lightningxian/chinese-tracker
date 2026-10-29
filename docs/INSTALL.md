# Install Easy Study (testers)

## Android (APK sideload — not Play Store)

1. Get `easy-study.apk` from your tester (or from a hosted download link once available).
2. On the phone, open the APK. Android will warn about an unknown source — allow installs from that browser / Files app.
3. Tap **Install**, then open **Easy Study** and sign in (needs internet for Firebase).

### Hosted download (landing page)

Firebase **Spark** (free) Hosting blocks `.apk` uploads. To enable **Download for Android** on the site:

1. Upgrade the Firebase project to **Blaze** (pay-as-you-go):  
   https://console.firebase.google.com/project/chinese-tracker/usage/details
2. Copy the APK into the web build and redeploy:

```bash
cp /path/to/easy-study.apk build/web/downloads/easy-study.apk
firebase deploy --only hosting
```

Expected URL: `https://easystudy.web.app/downloads/easy-study.apk`

Until that is live, the release APK built on this Mac is at:

`~/Projects/chinese-tracker/build/app/outputs/flutter-apk/app-release.apk`  
(or a copy at `/tmp/easystudy-artifacts/easy-study.apk`)

Share that file directly (AirDrop / Drive / WhatsApp) for Android testers.

## iPhone (PWA — not App Store)

No App Store build. Install the live web app to Home Screen:

1. Open **Safari** (not Chrome) → `https://easystudy.web.app`
2. Tap **Share** → **Add to Home Screen**
3. Confirm the name **Easy Study**, then **Add**
4. Open the Home Screen icon — it should launch full-screen (standalone)

Sign in once inside the PWA so Firebase Auth works in that standalone window.
