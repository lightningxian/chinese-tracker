import '../core/constants/app_constants.dart';

class SavedLoginAccount {
  const SavedLoginAccount({
    required this.email,
    required this.displayName,
    this.role,
    required this.lastUsedAt,
    this.isDemo = false,
  });

  final String email;
  final String displayName;
  final String? role;
  final DateTime lastUsedAt;
  final bool isDemo;

  String get roleLabel {
    return AppConstants.roleLabel(role);
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'displayName': displayName,
        'role': role,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };

  factory SavedLoginAccount.fromJson(Map<String, dynamic> json) {
    return SavedLoginAccount(
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? json['email'] as String,
      role: json['role'] as String?,
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  SavedLoginAccount copyWith({
    String? displayName,
    String? role,
    DateTime? lastUsedAt,
  }) {
    return SavedLoginAccount(
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isDemo: isDemo,
    );
  }
}

/// Built-in demo account from compile-time env (for local dev).
class DemoLoginAccount {
  const DemoLoginAccount({
    required this.email,
    required this.password,
    required this.displayName,
    required this.role,
  });

  final String email;
  final String password;
  final String displayName;
  final String role;

  SavedLoginAccount toSaved() => SavedLoginAccount(
        email: email,
        displayName: displayName,
        role: role,
        lastUsedAt: DateTime.now(),
        isDemo: true,
      );
}
