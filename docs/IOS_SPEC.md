# iOS for Easy Study: what it means (Q9, 2026-11-24)

The owner wants iOS. The proposal promises Android, iOS and web from one
Flutter codebase. There are two ways to give iPhone users the app. Both use
the same code and the same live database.

## Option A: installed web app (works today, free)

What the user does: open https://chinese-tracker.web.app in **Safari**, tap
**Share → Add to Home Screen**. The landing page already has an
**Install on iPhone** button that shows these steps.

What they get:
- An Easy Study icon on the home screen that opens full screen, without
  Safari's address bar (`display: standalone` in `web/manifest.json`, the
  `apple-mobile-web-app-*` tags in `web/index.html`).
- Every feature of the web app: classes, booking, exercises, tests, payments
  (Midtrans opens in the same window), progress, News.
- Updates at once with every deploy; nothing to install again.

Limits:
- Not in the App Store.
- Phone notifications (the lock-screen kind) need iOS 16.4 or newer and the
  app added to the home screen; the user must allow them once. The bell
  inside the app always works.
- Scanning papers and the transcript reader are admin tools for a computer,
  not a phone.

Cost: none. Work: none (already live). For the book: "iOS is served as an
installable web app (PWA)", with the steps above and a screenshot.

## Option B: a real App Store app (native iOS build)

What it needs, in order:
1. **An Apple Developer Program account**: USD 99 a year, in the centre's or
   the owner's name. Apple checks the identity; this can take a few days.
2. **A Mac with the full Xcode** (the owner's Mac has an incomplete Xcode
   today) and CocoaPods.
3. **The iOS app added in the Firebase console** (Project settings → Add app
   → iOS, bundle id e.g. `id.easystudy.app`) and its
   `GoogleService-Info.plist` placed in `ios/Runner/`. The owner does this
   by hand in the console: `flutterfire configure` must not be re-run
   (CLAUDE.md "Never").
4. Build the app: `flutter build ipa`, signed with the developer account.
5. **TestFlight** for the trial testers (up to 10,000 testers, no review
   wait beyond a short beta check).
6. **App Store review** for the public release (usually 1–3 days). Payments
   are for lessons taught at the centre, so Midtrans may stay (Apple's
   in-app purchase rule does not apply to services used outside the app).
7. A privacy policy page and the App Store screenshots and texts.

What Claude can do: prepare the iOS project settings, the bundle id, icons
and the build commands, and write the store texts. What only the owner can
do: pay for and sign in to the Apple account, add the iOS app in the Firebase
console, and run the build and upload on the Mac (signing needs the
owner's Apple ID).

Time: about one working day once the account is approved, plus the review.

## Recommendation

Option A for the trial and the seminar (it works today and the book can
show it). Option B only if the supervisor asks for a store app or the centre
wants one; start the Apple account early because approval can take days.
