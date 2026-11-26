import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/class_history_section.dart';
import '../../models/app_user.dart';

/// History tab: the student's vouchers with the classes charged to each,
/// then every class visit by month. Tapping a class opens who joined it.
/// Build 9A session 2: the visits are read 25 a page in a date range, and a
/// voucher reads its classes when it is opened.
class StudentMyClassesTab extends StatelessWidget {
  const StudentMyClassesTab({super.key, required this.student});

  final AppUser student;

  @override
  Widget build(BuildContext context) {
    return PagedClassHistory(
      studentId: student.uid,
      onOpenSession: (record) => context.push('/student/class/${record.sessionId}'),
    );
  }
}
