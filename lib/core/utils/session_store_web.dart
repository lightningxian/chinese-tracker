import 'package:web/web.dart' as web;

String? read(String key) {
  try {
    return web.window.sessionStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

void write(String key, String value) {
  try {
    web.window.sessionStorage.setItem(key, value);
  } catch (_) {}
}

void remove(String key) {
  try {
    web.window.sessionStorage.removeItem(key);
  } catch (_) {}
}
