import 'package:flutter/material.dart' show IconData, Icons;

/// Temporary test logins — replace with real login/register when done testing.
abstract final class TestAccounts {
  static const password = String.fromEnvironment(
    'TEST_PASSWORD',
    defaultValue: 'testpass123',
  );

  static const adminEmail = String.fromEnvironment(
    'TEST_ADMIN_EMAIL',
    defaultValue: 'admin@test.chinesetracker',
  );

  static const teacherEmail = String.fromEnvironment(
    'TEST_TEACHER_EMAIL',
    defaultValue: String.fromEnvironment(
      'DEMO_TEACHER_EMAIL',
      defaultValue: 'teacher@test.chinesetracker',
    ),
  );

  static const student1Email = String.fromEnvironment(
    'TEST_STUDENT1_EMAIL',
    defaultValue: String.fromEnvironment(
      'DEMO_STUDENT_EMAIL',
      defaultValue: 'student1@test.chinesetracker',
    ),
  );

  static const student2Email = String.fromEnvironment(
    'TEST_STUDENT2_EMAIL',
    defaultValue: 'student2@test.chinesetracker',
  );

  static const student3Email = String.fromEnvironment(
    'TEST_STUDENT3_EMAIL',
    defaultValue: 'student3@test.chinesetracker',
  );

  static List<TestAccount> get adminOptions => [
        const TestAccount(
          label: 'Admin',
          email: adminEmail,
          icon: Icons.shield_outlined,
          isAdmin: true,
          subtitle: 'Users, vouchers, reports, notifications',
        ),
      ];

  static List<TestAccount> get teacherOptions => [
        const TestAccount(
          label: 'Guru',
          email: teacherEmail,
          icon: Icons.school_outlined,
          isTeacher: true,
          subtitle: 'Students, classes, attendance',
        ),
      ];

  static List<TestAccount> get studentOptions => [
        const TestAccount(
          label: 'Murid 1',
          email: student1Email,
          icon: Icons.person_outline,
        ),
        const TestAccount(
          label: 'Murid 2',
          email: student2Email,
          icon: Icons.person_outline,
        ),
        const TestAccount(
          label: 'Murid 3',
          email: student3Email,
          icon: Icons.person_outline,
        ),
      ];

  static List<TestAccount> get options => [
        ...adminOptions,
        ...teacherOptions,
        ...studentOptions,
      ];
}

class TestAccount {
  const TestAccount({
    required this.label,
    required this.email,
    required this.icon,
    this.isTeacher = false,
    this.isAdmin = false,
    this.subtitle,
  });

  final String label;
  final String email;
  final IconData icon;
  final bool isTeacher;
  final bool isAdmin;
  final String? subtitle;

  String get password => TestAccounts.password;
}
