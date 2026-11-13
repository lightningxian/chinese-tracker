import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/build_flags.dart';

/// Push notifications (Firebase Cloud Messaging) on web and Android.
///
/// A device opts in from the profile tab: the browser asks for permission,
/// the FCM token is stored in `push_tokens/{token}` with the signed-in uid,
/// and the `onNotificationCreated` function sends every notification
/// addressed to that uid to the device. Web needs the VAPID key
/// (`BuildFlags.fcmVapidKey`); without it the switch is hidden and nothing
/// here runs. Broadcast notifications (`userId == ''`) are not pushed yet.
class PushService extends ChangeNotifier {
  static const collection = 'push_tokens';

  /// The build carries a VAPID key and the platform can show notifications.
  static bool get isAvailable =>
      BuildFlags.fcmVapidKey.isNotEmpty &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.android);

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// A message that arrived while the app was in front; the app shows it.
  final foregroundMessage = ValueNotifier<RemoteMessage?>(null);

  StreamSubscription<RemoteMessage>? _onMessage;

  /// False on a browser without the Push API (e.g. iOS Safari outside the
  /// home-screen app).
  bool _supported = true;
  bool get supported => isAvailable && _supported;

  bool _enabled = false;

  /// This device pushes for the signed-in user.
  bool get enabled => _enabled;

  /// The user refused notifications in the browser / system settings.
  bool _blocked = false;
  bool get blocked => _blocked;

  bool _busy = false;
  bool get busy => _busy;

  String? _token;

  Future<void> init() async {
    if (!isAvailable) return;
    try {
      if (kIsWeb && !await _messaging.isSupported()) {
        _supported = false;
        return;
      }
      _onMessage = FirebaseMessaging.onMessage
          .listen((message) => foregroundMessage.value = message);
    } catch (e) {
      debugPrint('Push: not available: $e');
      _supported = false;
    }
  }

  String? get _vapidKey => kIsWeb ? BuildFlags.fcmVapidKey : null;

  /// Reads the device state for [uid]: enabled when notifications are
  /// allowed and this device's token is on file for that user. Never asks
  /// for permission.
  Future<void> sync(String uid) async {
    if (!supported) return;
    _busy = true;
    notifyListeners();
    try {
      final settings = await _messaging.getNotificationSettings();
      _blocked = settings.authorizationStatus == AuthorizationStatus.denied;
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _enabled = false;
        return;
      }
      final token = await _messaging.getToken(vapidKey: _vapidKey);
      _token = token;
      if (token == null) {
        _enabled = false;
        return;
      }
      final snap = await _db.collection(collection).doc(token).get();
      _enabled = snap.exists && snap.data()?['uid'] == uid;
    } catch (e) {
      debugPrint('Push: sync failed: $e');
      _enabled = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Asks for permission and registers this device for [uid]. Returns false
  /// when the user refused or the token could not be stored.
  Future<bool> enable(String uid) async {
    if (!supported) return false;
    _busy = true;
    notifyListeners();
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        _blocked = settings.authorizationStatus == AuthorizationStatus.denied;
        _enabled = false;
        return false;
      }
      _blocked = false;
      var token = await _messaging.getToken(vapidKey: _vapidKey);
      if (token == null) return false;
      try {
        await _store(token, uid);
      } on FirebaseException catch (e) {
        // The token was registered to another account on this device (the
        // rules let only its owner change it): take a fresh token instead.
        if (e.code != 'permission-denied') rethrow;
        await _messaging.deleteToken();
        token = await _messaging.getToken(vapidKey: _vapidKey);
        if (token == null) return false;
        await _store(token, uid);
      }
      _token = token;
      _enabled = true;
      return true;
    } catch (e) {
      debugPrint('Push: enable failed: $e');
      _enabled = false;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _store(String token, String uid) {
    return _db.collection(collection).doc(token).set({
      'uid': uid,
      'platform': kIsWeb ? 'web' : 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unregisters this device. A token doc that belongs to another account
  /// is left alone (the rules refuse it); the server drops it on the first
  /// failed send.
  Future<void> disable() async {
    if (!supported) return;
    _busy = true;
    notifyListeners();
    try {
      final token = _token ?? await _messaging.getToken(vapidKey: _vapidKey);
      if (token != null) {
        try {
          await _db.collection(collection).doc(token).delete();
        } catch (e) {
          debugPrint('Push: token doc not removed: $e');
        }
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Push: disable failed: $e');
    } finally {
      _token = null;
      _enabled = false;
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _onMessage?.cancel();
    foregroundMessage.dispose();
    super.dispose();
  }
}
