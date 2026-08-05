import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/saved_login_account.dart';

class SavedAccountsService extends ChangeNotifier {
  SavedAccountsService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accountsKey = 'saved_login_accounts';

  final FlutterSecureStorage _secureStorage;
  List<SavedLoginAccount> _accounts = [];
  bool _loaded = false;

  List<SavedLoginAccount> get accounts => List.unmodifiable(_accounts);
  bool get isLoaded => _loaded;

  static List<DemoLoginAccount> get demoAccounts {
    const studentEmail = String.fromEnvironment('DEMO_STUDENT_EMAIL');
    const studentPassword = String.fromEnvironment('DEMO_STUDENT_PASSWORD');

    if (studentEmail.isEmpty || studentPassword.isEmpty) {
      return const [];
    }
    return [
      DemoLoginAccount(
        email: studentEmail,
        password: studentPassword,
        displayName: 'Demo account',
        role: 'student',
      ),
    ];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      _accounts = list
          .map((e) => SavedLoginAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _accounts = [];
    }
    _loaded = true;
    notifyListeners();
  }

  List<LoginListEntry> buildLoginList() {
    final demos = demoAccounts;
    final byEmail = <String, LoginListEntry>{};

    for (final demo in demos) {
      byEmail[demo.email.toLowerCase()] = LoginListEntry(
        account: demo.toSaved(),
        demo: demo,
      );
    }

    for (final saved in _accounts) {
      final key = saved.email.toLowerCase();
      final existing = byEmail[key];
      if (existing != null) {
        byEmail[key] = LoginListEntry(
          account: saved.copyWith(
            displayName: saved.displayName.isNotEmpty
                ? saved.displayName
                : existing.account.displayName,
            role: saved.role ?? existing.account.role,
          ),
          demo: existing.demo,
        );
      } else {
        byEmail[key] = LoginListEntry(account: saved);
      }
    }

    final entries = byEmail.values.toList();
    entries.sort((a, b) {
      if (a.demo != null && b.demo == null) return -1;
      if (a.demo == null && b.demo != null) return 1;
      return b.account.lastUsedAt.compareTo(a.account.lastUsedAt);
    });
    return entries;
  }

  Future<void> recordSuccessfulLogin(
    AppUser user, {
    String? password,
    bool rememberPassword = false,
  }) async {
    final now = DateTime.now();
    final email = user.email.toLowerCase();
    final idx = _accounts.indexWhere((a) => a.email.toLowerCase() == email);
    final updated = SavedLoginAccount(
      email: user.email,
      displayName: user.name,
      role: user.role,
      lastUsedAt: now,
    );
    if (idx >= 0) {
      _accounts[idx] = updated;
    } else {
      _accounts.add(updated);
    }
    _accounts.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    await _persist();

    if (rememberPassword && password != null && password.isNotEmpty) {
      await _secureStorage.write(key: _passwordKey(user.email), value: password);
    } else if (!rememberPassword) {
      await _secureStorage.delete(key: _passwordKey(user.email));
    }
    notifyListeners();
  }

  Future<String?> getStoredPassword(String email) {
    return _secureStorage.read(key: _passwordKey(email));
  }

  Future<bool> hasStoredPassword(String email) async {
    final pwd = await getStoredPassword(email);
    return pwd != null && pwd.isNotEmpty;
  }

  Future<void> removeAccount(String email) async {
    _accounts.removeWhere((a) => a.email.toLowerCase() == email.toLowerCase());
    await _secureStorage.delete(key: _passwordKey(email));
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_accountsKey, encoded);
  }

  static String _passwordKey(String email) =>
      'login_pwd_${email.trim().toLowerCase()}';
}

class LoginListEntry {
  const LoginListEntry({required this.account, this.demo});

  final SavedLoginAccount account;
  final DemoLoginAccount? demo;
}
