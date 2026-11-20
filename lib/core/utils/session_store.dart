// The browser tab's sessionStorage (Build 3: a visitor's placement attempt
// survives a reload of the tab, and is gone when the tab closes). Off the
// web it is a plain in-memory map.
import 'session_store_stub.dart'
    if (dart.library.js_interop) 'session_store_web.dart' as impl;

class SessionStore {
  static String? read(String key) => impl.read(key);
  static void write(String key, String value) => impl.write(key, value);
  static void remove(String key) => impl.remove(key);
}
