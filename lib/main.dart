import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/constants/build_flags.dart';
import 'core/utils/emulator_guard.dart';
import 'firebase_options.dart';

/// `flutter run --dart-define=USE_EMULATORS=true` points the app at the local
/// Firebase Emulator Suite (ports from firebase.json) instead of the live
/// project. Seed it with `python3 scripts/seed_emulator.py`.
Future<void> _connectToEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  debugPrint('Connected to Firebase emulators on $host');
}

/// Firebase App Check: proves requests come from this app. Web uses
/// reCAPTCHA Enterprise (score-based "Website" key from Google Cloud
/// console → Security → reCAPTCHA, passed as
/// `--dart-define=APP_CHECK_SITE_KEY`; the console no longer offers v3 keys,
/// 2026-11-16), or the debug provider on local runs
/// (`APP_CHECK_DEBUG=true`); Android uses Play
/// Integrity in release builds and the debug provider in debug builds.
/// Skipped until the owner has set a site key, so the app keeps working
/// before the console setup. Firebase AI Logic (worksheet import) requires
/// App Check; Firestore, Functions and Storage are left unenforced in the
/// console because the Android APK is sideloaded (no Play Integrity verdict).
/// A failure here must never block startup.
Future<void> _activateAppCheck() async {
  final configured =
      BuildFlags.appCheckSiteKey.isNotEmpty || BuildFlags.appCheckDebug;
  if (!configured) return;
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: BuildFlags.appCheckDebug
          ? WebDebugProvider()
          : ReCaptchaEnterpriseProvider(BuildFlags.appCheckSiteKey),
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
    );
  } catch (e) {
    debugPrint('App Check could not start: $e');
  }
}

Future<void> main() async {
  await runZonedGuarded(() async {
    // Clean web addresses (/login, not /#/login). Hosting rewrites every
    // path to index.html, so deep links and refreshes resolve. No-op off web.
    usePathUrlStrategy();
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught async error: $error\n$stack');
      }
      return true;
    };

    await pdfrxFlutterInitialize();
    // Month and weekday names for Indonesian dates (LocaleController sets
    // Intl.defaultLocale); English is built in.
    await initializeDateFormatting('id');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _activateAppCheck();
    if (BuildFlags.useEmulators) {
      await _connectToEmulators();
      if (!authEmulatorAttached()) {
        // Auth started before the emulator could be attached (a reload with
        // a signed-in user): it would talk to the LIVE project. Drop the
        // local session (no network) and reload once; if that does not
        // help, refuse to start rather than sign anyone in to live.
        await FirebaseAuth.instance.signOut();
        if (takeEmulatorRetry()) {
          reloadPage();
          return;
        }
        runApp(const _EmulatorNotAttachedApp());
        return;
      }
      resetEmulatorRetry();
    }
    runApp(const ChineseTrackerApp());
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
    }
  });
}

/// Emulator build whose Auth could not be attached to the local emulator:
/// nothing starts, so nobody can sign in to the live project by accident.
class _EmulatorNotAttachedApp extends StatelessWidget {
  const _EmulatorNotAttachedApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'EMULATOR build: Firebase Auth is not attached to the local '
              'emulator, so the app did not start (it would sign in to the '
              'LIVE project). Close this tab and open the app in a new one.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
