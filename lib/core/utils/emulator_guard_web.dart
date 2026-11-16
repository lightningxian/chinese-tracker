import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// True when the Firebase JS Auth instance has an emulator config. FlutterFire
/// loads the Firebase JS SDK as `window.firebase_core` / `window.firebase_auth`.
bool authEmulatorAttached() {
  try {
    final core = globalContext.getProperty<JSObject?>('firebase_core'.toJS);
    final auth = globalContext.getProperty<JSObject?>('firebase_auth'.toJS);
    if (core == null || auth == null) return true; // cannot tell: do not block
    final app = core.callMethod<JSObject>('getApp'.toJS);
    final instance = auth.callMethod<JSObject>('getAuth'.toJS, app);
    final config = instance.getProperty<JSAny?>('emulatorConfig'.toJS);
    return config != null;
  } catch (_) {
    return true;
  }
}

const _retryKey = 'emulator_guard_retry';

/// True the first time in this tab (then a reload is tried once).
bool takeEmulatorRetry() {
  try {
    final storage = web.window.sessionStorage;
    if (storage.getItem(_retryKey) != null) return false;
    storage.setItem(_retryKey, '1');
    return true;
  } catch (_) {
    return false;
  }
}

void reloadPage() => web.window.location.reload();

/// Auth attached: allow one retry again for a later reload.
void resetEmulatorRetry() {
  try {
    web.window.sessionStorage.removeItem(_retryKey);
  } catch (_) {}
}
