import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels_admin.dart';
import '../../models/app_user.dart';
import '../../services/firestore_service.dart';
import '../../services/profile_photo_service.dart';
import 'app_card.dart';
import 'app_shell.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.user,
    this.subtitle,
    this.avatarColor,
    this.onPhotoChanged,
    this.canEditPhoto = false,
  });

  final AppUser user;
  final String? subtitle;
  final Color? avatarColor;
  final ValueChanged<String>? onPhotoChanged;
  final bool canEditPhoto;

  @override
  Widget build(BuildContext context) {
    final color = avatarColor ??
        (user.isStudent
            ? AppColors.teal
            : user.isTeacher
                ? AppColors.navy
                : const Color(0xFF7A4FBF));
    final chinese = user.displayNameChinese;

    return AppCard(
      child: Row(
        children: [
          ProfilePhotoAvatar(
            user: user,
            size: 64,
            backgroundColor: color,
            canEdit: canEditPhoto,
            onPhotoChanged: onPhotoChanged,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayNameIndonesian,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (chinese != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    chinese,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                Text(user.email),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ProfileRoleChip(
                        label: user.roleLocalized(context.l10n), color: color),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePhotoAvatar extends StatefulWidget {
  ProfilePhotoAvatar({
    super.key,
    required this.user,
    this.size = 56,
    Color? backgroundColor,
    this.canEdit = false,
    this.onPhotoChanged,
  }) : backgroundColor = backgroundColor ?? AppColors.navy;

  final AppUser user;
  final double size;
  final Color backgroundColor;
  final bool canEdit;
  final ValueChanged<String>? onPhotoChanged;

  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    if (!widget.canEdit || _uploading) return;

    setState(() => _uploading = true);
    try {
      final url = await ProfilePhotoService().pickAndUpload(widget.user.uid);
      if (!mounted) return;
      await context.read<FirestoreService>().updateUserProfile(
            userId: widget.user.uid,
            photoUrl: url,
          );
      if (!mounted) return;
      widget.onPhotoChanged?.call(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileWidgetPhotoUpdated)),
      );
    } on ProfilePhotoCancelledException {
      // User cancelled picker — ignore.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = AppUserAvatar(
      initials: userInitials(widget.user.displayNameIndonesian),
      size: widget.size,
      backgroundColor: widget.backgroundColor,
      photoUrl: widget.user.photoUrl,
    );

    if (!widget.canEdit) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: AppColors.navy,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _uploading ? null : _pickPhoto,
              child: SizedBox(
                width: 28,
                height: 28,
                child: _uploading
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        size: 14,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileRoleChip extends StatelessWidget {
  const ProfileRoleChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePersonalFields extends StatelessWidget {
  const ProfilePersonalFields({
    super.key,
    required this.nameIndonesianController,
    required this.nameChineseController,
    required this.whatsappController,
    required this.email,
    required this.enabled,
    this.showParentFields = false,
    this.parentNameController,
    this.parentPhoneController,
  });

  final TextEditingController nameIndonesianController;
  final TextEditingController nameChineseController;
  final TextEditingController whatsappController;
  final String email;
  final bool enabled;
  final bool showParentFields;
  final TextEditingController? parentNameController;
  final TextEditingController? parentPhoneController;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        TextFormField(
          controller: nameIndonesianController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l.identityNameIndonesian,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? l.identityNameIndonesianRequired
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nameChineseController,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: l.identityNameChinese,
            hintText: '中文名',
            prefixIcon: const Icon(Icons.translate_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: email,
          readOnly: true,
          decoration: InputDecoration(
            labelText: l.commonEmail,
            prefixIcon: const Icon(Icons.email_outlined),
            helperText: l.profileWidgetEmailHelper,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: whatsappController,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: l.identityWhatsapp,
            hintText: '08xxxxxxxxxx',
            prefixIcon: const Icon(Icons.chat_outlined),
          ),
        ),
        if (showParentFields &&
            parentNameController != null &&
            parentPhoneController != null) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.identityParentSection,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.profileWidgetParentHint,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: parentNameController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.identityParentName,
              prefixIcon: const Icon(Icons.family_restroom_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: parentPhoneController,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.identityParentPhone,
              hintText: '08xxxxxxxxxx',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
        ],
      ],
    );
  }
}

class ProfileStudentLearningFields extends StatelessWidget {
  const ProfileStudentLearningFields({
    super.key,
    required this.level,
    required this.termSize,
    required this.enabled,
    required this.onLevelChanged,
    required this.onTermSizeChanged,
  });

  final String level;
  final int termSize;
  final bool enabled;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<int> onTermSizeChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: level,
          decoration: InputDecoration(
            labelText: l.commonHskLevel,
            prefixIcon: const Icon(Icons.school_outlined),
          ),
          items: AppConstants.hskLevels
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: enabled ? (value) => onLevelChanged(value ?? level) : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: termSize,
          decoration: InputDecoration(
            labelText: l.commonLessonsPerTerm,
            prefixIcon: const Icon(Icons.calendar_view_week_outlined),
          ),
          items: AppConstants.termSizes
              .map(
                (size) => DropdownMenuItem(
                  value: size,
                  child: Text(l.commonLessonsPerTermOption(size)),
                ),
              )
              .toList(),
          onChanged:
              enabled ? (value) => onTermSizeChanged(value ?? termSize) : null,
        ),
      ],
    );
  }
}

class ProfileAccountMeta extends StatelessWidget {
  const ProfileAccountMeta({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final joined = user.createdAt == null
        ? '—'
        : DateFormat('d MMM yyyy').format(user.createdAt!);

    return ProfileSectionCard(
      title: l.profileWidgetAccountTitle,
      children: [
        ProfileInfoRow(
          label: l.profileWidgetMemberSince,
          value: joined,
          icon: Icons.calendar_today_outlined,
        ),
        ProfileInfoRow(
          label: l.profileWidgetStatus,
          value: user.active ? l.historyStatusActive : l.profileWidgetInactive,
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}

class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({
    super.key,
    required this.saving,
    required this.onPressed,
  });

  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: saving ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(context.l10n.profileWidgetSaveChanges),
    );
  }
}

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(context.l10n.commonSignOut),
    );
  }
}
