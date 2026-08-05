import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/profile_widgets.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';

class AdminEditUserScreen extends StatefulWidget {
  const AdminEditUserScreen({
    super.key,
    required this.userId,
    this.embedded = false,
  });

  final String userId;
  final bool embedded;

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameIndonesianController = TextEditingController();
  final _nameChineseController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  AppUser? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _level = AppConstants.hskLevels.first;
  int _termSize = AppConstants.defaultTermSize;

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  Future<void> _loadUser() async {
    final user =
        await context.read<FirestoreService>().getUser(widget.userId);
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'User not found';
      });
      return;
    }

    _nameIndonesianController.text = user.displayNameIndonesian;
    _nameChineseController.text = user.nameChinese ?? '';
    _whatsappController.text = user.displayWhatsapp ?? '';
    _parentNameController.text = user.parentName ?? '';
    _parentPhoneController.text = user.parentPhone ?? '';
    setState(() {
      _user = user;
      _level = user.level ?? AppConstants.hskLevels.first;
      _termSize = user.termSize ?? AppConstants.defaultTermSize;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final indonesian = _nameIndonesianController.text.trim();
      await context.read<FirestoreService>().updateUserProfile(
            userId: user.uid,
            name: indonesian,
            nameIndonesian: indonesian,
            nameChinese: _nameChineseController.text,
            whatsapp: _whatsappController.text,
            parentName: user.isStudent ? _parentNameController.text : null,
            parentPhone: user.isStudent ? _parentPhoneController.text : null,
            level: user.isStudent ? _level : null,
            termSize: user.isStudent ? _termSize : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$indonesian updated')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return ShellNestedPage(
      embedded: widget.embedded,
      title: user == null ? 'Edit user' : 'Edit ${user.roleDisplayLabel}',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(
                  child: Text(
                    _error ?? 'User not found',
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ProfileHeaderCard(
                      user: user,
                      canEditPhoto: true,
                      onPhotoChanged: (url) {
                        setState(() {
                          _user = AppUser(
                            uid: user.uid,
                            email: user.email,
                            name: user.name,
                            role: user.role,
                            teacherId: user.teacherId,
                            level: user.level,
                            termSize: user.termSize,
                            nameIndonesian: user.nameIndonesian,
                            nameChinese: user.nameChinese,
                            whatsapp: user.whatsapp,
                            photoUrl: url,
                            parentName: user.parentName,
                            parentPhone: user.parentPhone,
                            phone: user.phone,
                            createdAt: user.createdAt,
                            active: user.active,
                          );
                        });
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
                    ],
                    const SizedBox(height: 16),
                    AppCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Profile details',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                            ),
                            if (user.isStudent) ...[
                              const SizedBox(height: 4),
                              const Text(
                                'Change HSK level to control which practice '
                                'exercises this murid can access.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ProfilePersonalFields(
                              nameIndonesianController:
                                  _nameIndonesianController,
                              nameChineseController: _nameChineseController,
                              whatsappController: _whatsappController,
                              email: user.email,
                              enabled: !_saving,
                              showParentFields: user.isStudent,
                              parentNameController: _parentNameController,
                              parentPhoneController: _parentPhoneController,
                            ),
                            if (user.isStudent) ...[
                              const SizedBox(height: 16),
                              ProfileStudentLearningFields(
                                level: _level,
                                termSize: _termSize,
                                enabled: !_saving,
                                onLevelChanged: (value) =>
                                    setState(() => _level = value),
                                onTermSizeChanged: (value) =>
                                    setState(() => _termSize = value),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileAccountMeta(user: user),
                    const SizedBox(height: 24),
                    ProfileSaveButton(saving: _saving, onPressed: _save),
                  ],
                ),
    );
  }
}
