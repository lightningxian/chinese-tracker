import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/profile_widgets.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/widgets/teacher_student_link_card.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class TeacherProfileTab extends StatefulWidget {
  const TeacherProfileTab({super.key, required this.user});

  final AppUser user;

  @override
  State<TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<TeacherProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameIndonesianController;
  late final TextEditingController _nameChineseController;
  late final TextEditingController _whatsappController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameIndonesianController = TextEditingController();
    _nameChineseController = TextEditingController();
    _whatsappController = TextEditingController();
    _applyUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant TeacherProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid ||
        oldWidget.user.name != widget.user.name ||
        oldWidget.user.nameIndonesian != widget.user.nameIndonesian ||
        oldWidget.user.nameChinese != widget.user.nameChinese ||
        oldWidget.user.whatsapp != widget.user.whatsapp ||
        oldWidget.user.phone != widget.user.phone ||
        oldWidget.user.photoUrl != widget.user.photoUrl) {
      _applyUser(widget.user);
    }
  }

  void _applyUser(AppUser user) {
    _nameIndonesianController.text = user.displayNameIndonesian;
    _nameChineseController.text = user.nameChinese ?? '';
    _whatsappController.text = user.displayWhatsapp ?? '';
  }

  @override
  void dispose() {
    _nameIndonesianController.dispose();
    _nameChineseController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l = context.l10n;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final firestore = context.read<FirestoreService>();
      final auth = context.read<AuthService>();
      final indonesian = _nameIndonesianController.text.trim();
      await firestore.updateUserProfile(
        userId: widget.user.uid,
        name: indonesian,
        nameIndonesian: indonesian,
        nameChinese: _nameChineseController.text,
        whatsapp: _whatsappController.text,
      );
      if (!mounted) return;
      await auth.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.studentProfileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final l = context.l10n;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProfileHeaderCard(
            user: user,
            subtitle: l.teacherProfileRoleSubtitle,
            avatarColor: AppColors.navy,
            canEditPhoto: true,
            onPhotoChanged: (_) async {
              await context.read<AuthService>().refreshProfile();
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          ProfileSectionCard(
            title: l.studentProfilePersonalTitle,
            subtitle: l.teacherProfilePersonalSubtitle,
            children: [
              ProfilePersonalFields(
                nameIndonesianController: _nameIndonesianController,
                nameChineseController: _nameChineseController,
                whatsappController: _whatsappController,
                email: user.email,
                enabled: !_saving,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TeacherStudentLinkCard(teacherId: user.uid),
          const SizedBox(height: 16),
          const AppCard(child: LanguageSettingRow()),
          const SizedBox(height: 16),
          const AppCard(child: ThemeSettingRow()),
          const SizedBox(height: 16),
          const AppCard(child: TextSizeSettingRow()),
          const SizedBox(height: 16),
          ProfileAccountMeta(user: user),
          const SizedBox(height: 24),
          ProfileSaveButton(saving: _saving, onPressed: _save),
          const SizedBox(height: 12),
          ProfileSignOutButton(
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
