/// Off the web the plugins attach the emulators before any request.
bool authEmulatorAttached() => true;

/// One retry per browser tab; never needed off the web.
bool takeEmulatorRetry() => false;

void reloadPage() {}

void resetEmulatorRetry() {}
