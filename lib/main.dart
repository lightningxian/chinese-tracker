import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'core/constants/build_flags.dart';
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (BuildFlags.useEmulators) await _connectToEmulators();
    runApp(const ChineseTrackerApp());
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
    }
  });
}
