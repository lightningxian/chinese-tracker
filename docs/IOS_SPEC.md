# iOS for Easy Study (Q9)

**Owner decision 2026-11-24: option B, a real App Store app.** Option A (the
installed web app: Safari → Share → Add to Home Screen) keeps working for
anyone who prefers it and needs nothing.

## What is ready in the code (BUILD chat, 2026-11-24)

- The iOS project builds the same Flutter app as web and Android, against
  the same live database. The iOS app is already registered in Firebase
  (bundle id `com.chinesetracker.chineseTracker`, its
  `ios/Runner/GoogleService-Info.plist` is in the repo), so **nothing has to
  be added in the Firebase console** and `flutterfire configure` stays
  untouched.
- App name **Easy Study**, the pencil-mascot icon (also on Android now:
  `tool/make_app_icons.ps1`), iPhone only (it still runs on an iPad in
  iPhone mode, and Apple then asks for no iPad screenshots), iOS 15 or newer
  (current Firebase needs it; `ios/Podfile`).
- Texts Apple asks for: why the app may open photos or the camera (only when
  the user picks a file), and "no special encryption" (so App Store Connect
  does not ask the export question at every upload).
- Apple's rule 5.1.1(v): **Delete my account** on the student and parent
  profile tabs and on the waiting screen (`deleteMyAccount`; the password is
  asked again; records the centre needs stay).
- A public **privacy policy** at https://chinese-tracker.web.app/privacy
  (English and Indonesian, linked from the landing page footer).
- `scripts/build_ios.sh` builds the archive on the Mac with the same settings
  as the web and Android builds.

Not in the first iOS version, on purpose:
- Lock-screen notifications on iOS (the in-app bell works). They need an
  Apple push key uploaded to Firebase; the app's push code is web and
  Android only today. A later step if the centre wants it.
- The admin tools that read papers and recordings run in a desktop browser
  only (as on Android).

## What the owner does (in this order)

1. **Apple Developer Program** (USD 99 a year) at developer.apple.com/programs.
   - *Individual*: quick; the store shows the owner's own name as the seller.
   - *Organization*: the store shows the centre's name, but Apple needs a
     D-U-N-S number for the business (free, can take one to two weeks).
   Approval can take a few days, so start now.
2. **Xcode on the Mac**: install the full Xcode from the Mac App Store (about
   15 GB), open it once and accept the licence, then
   `brew install cocoapods`. In Xcode → Settings → Accounts, add the Apple ID
   of the developer account.
3. **Signing**: open `ios/Runner.xcworkspace` in Xcode → Runner target →
   Signing & Capabilities → tick *Automatically manage signing* and choose
   the team. Xcode registers the bundle id `com.chinesetracker.chineseTracker`.
4. **App Store Connect** (appstoreconnect.apple.com) → My Apps → + → New App:
   name *Easy Study* (or *Easy Study Mandarin* if the name is taken),
   primary language Indonesian, bundle id `com.chinesetracker.chineseTracker`,
   SKU e.g. `easystudy-ios`.
5. **Build and upload** on the Mac: `scripts/build_ios.sh`, then Xcode →
   Window → Organizer → Distribute App → App Store Connect (or Apple's
   Transporter app with `build/ios/ipa/*.ipa`). A Claude chat on the Mac can
   run the script; the owner signs in to Xcode.
6. **TestFlight**: add the trial testers by email (internal testers need no
   review; external testers get a short beta check). Testers install the
   TestFlight app and open the invitation.
7. **Store page**:
   - Screenshots of an iPhone 6.9" (1320 × 2868) and 6.5" (1284 × 2778).
     Claude can make them from the emulator.
   - Description, keywords, support URL (the landing page), privacy policy
     URL `https://chinese-tracker.web.app/privacy`.
   - Age rating: 4+.
   - *App Privacy* questions: name, email address, user content (answers,
     notes), purchase history; all *linked to the user*, *not used for
     tracking*.
8. **App review notes**: a demo student account (one of the live test
   students, password in `docs/CLAUDE_FULL_HANDOFF.md`) and two sentences:
   "Payments are for face-to-face Mandarin lessons at our centre in
   Surabaya, paid through Midtrans (guideline 3.1.3(e)). Account deletion:
   Profile → Delete my account." Review usually takes one to three days.

## Things to know

- **Payments stay in Midtrans sandbox** until the sandbox test MT-05 passes
  and the owner switches to production keys (CLAUDE.md "Never"). Testers can
  "pay" with sandbox cards; real money needs the production switch first,
  for web, Android and iOS alike.
- Every upload needs a higher build number; `scripts/build_ios.sh` uses the
  commit count.
- An update to the iOS app goes through review again; the web app and the
  data change at once as today.
