// Emulator builds only (`USE_EMULATORS=true`): checks that Firebase Auth is
// really attached to the local emulator.
//
// Found 2026-11-16: on the web, a reload with a signed-in user starts
// Firebase Auth before `useAuthEmulator` runs; the call then fails silently
// and Auth stays on the LIVE project while Firestore uses the emulator. A
// sign-in after that (for example a saved account) reached live Auth.
export 'emulator_guard_stub.dart'
    if (dart.library.js_interop) 'emulator_guard_web.dart';
