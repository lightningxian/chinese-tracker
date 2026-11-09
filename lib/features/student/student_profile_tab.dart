import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter/services.dart';

import '../../core/utils/progress_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/class_term_widgets.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/profile_widgets.dart';
import '../../l10n/l10n.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key, required this.user});

  final AppUser user;

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameIndonesianController;
  late final TextEditingController _nameChineseController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late String _level;
  late int _termSize;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameIndonesianController = TextEditingController();
    _nameChineseController = TextEditingController();
    _whatsappController = TextEditingController();
    _parentNameController = TextEditingController();
    _parentPhoneController = TextEditingController();
    _applyUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant StudentProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid ||
        oldWidget.user.name != widget.user.name ||
        oldWidget.user.nameIndonesian != widget.user.nameIndonesian ||
        oldWidget.user.nameChinese != widget.user.nameChinese ||
        oldWidget.user.whatsapp != widget.user.whatsapp ||
        oldWidget.user.phone != widget.user.phone ||
        oldWidget.user.parentName != widget.user.parentName ||
        oldWidget.user.parentPhone != widget.user.parentPhone ||
        oldWidget.user.photoUrl != widget.user.photoUrl ||
        oldWidget.user.level != widget.user.level ||
        oldWidget.user.termSize != widget.user.termSize) {
      _applyUser(widget.user);
    }
  }

  void _applyUser(AppUser user) {
    _nameIndonesianController.text = user.displayNameIndonesian;
    _nameChineseController.text = user.nameChinese ?? '';
    _whatsappController.text = user.displayWhatsapp ?? '';
    _parentNameController.text = user.parentName ?? '';
    _parentPhoneController.text = user.parentPhone ?? '';
    _level = user.level ?? AppConstants.hskLevels.first;
    _termSize = user.termSize ?? AppConstants.defaultTermSize;
  }

  @override
  void dispose() {
    _nameIndonesianController.dispose();
    _nameChineseController.dispose();
    _whatsappController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
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
        parentName: _parentNameController.text,
        parentPhone: _parentPhoneController.text,
        level: _level,
        termSize: _termSize,
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
            subtitle: ProgressUtils.formatStudentLevel(user),
            avatarColor: AppColors.teal,
            canEditPhoto: true,
            onPhotoChanged: (_) async {
              await context.read<AuthService>().refreshProfile();
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 16),
          ProfileSectionCard(
            title: l.studentProfilePersonalTitle,
            subtitle: l.studentProfilePersonalSubtitle,
            children: [
              ProfilePersonalFields(
                nameIndonesianController: _nameIndonesianController,
                nameChineseController: _nameChineseController,
                whatsappController: _whatsappController,
                email: user.email,
                enabled: !_saving,
                showParentFields: true,
                parentNameController: _parentNameController,
                parentPhoneController: _parentPhoneController,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProfileSectionCard(
            title: l.studentProfileLearningTitle,
            subtitle: l.studentProfileLearningSubtitle,
            children: [
              ProfileStudentLearningFields(
                level: _level,
                termSize: _termSize,
                enabled: !_saving,
                onLevelChanged: (value) => setState(() => _level = value),
                onTermSizeChanged: (value) => setState(() => _termSize = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StudentClassTermSection(studentId: user.uid),
          const SizedBox(height: 16),
          _ParentAccessCard(
            studentId: user.uid,
            initialCode: user.parentCode,
          ),
          const SizedBox(height: 16),
          const AppCard(child: LanguageSettingRow()),
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

/// Shows / generates the stable code a parent enters to link to this student.
class _ParentAccessCard extends StatefulWidget {
  const _ParentAccessCard({required this.studentId, this.initialCode});

  final String studentId;
  final String? initialCode;

  @override
  State<_ParentAccessCard> createState() => _ParentAccessCardState();
}

class _ParentAccessCardState extends State<_ParentAccessCard> {
  String? _code;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _code = widget.initialCode;
  }

  Future<void> _generate() async {
    final l = context.l10n;
    setState(() => _loading = true);
    try {
      final code = await context
          .read<FirestoreService>()
          .ensureParentCode(widget.studentId);
      if (mounted) setState(() => _code = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.studentProfileCodeFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.studentProfileParentAccessTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.studentProfileParentAccessBody,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (_code != null && _code!.isNotEmpty)
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _code!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: 3,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.commonCopy,
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _code!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.studentProfileCodeCopied)),
                    );
                  },
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.vpn_key_outlined),
              label: Text(l.studentProfileShowParentCode),
            ),
        ],
      ),
    );
  }
}
