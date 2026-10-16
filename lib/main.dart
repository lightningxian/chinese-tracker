import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app.dart';
import 'firebase_options.dart';

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
    runApp(const ChineseTrackerApp());
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
    }
  });
}
