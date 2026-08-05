import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
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
                    style: const TextStyle(
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
                    ProfileRoleChip(label: user.roleDisplayLabel, color: color),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
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
  const ProfilePhotoAvatar({
    super.key,
    required this.user,
    this.size = 56,
    this.backgroundColor = AppColors.navy,
    this.canEdit = false,
    this.onPhotoChanged,
  });

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
        const SnackBar(content: Text('Profile photo updated')),
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
              style: const TextStyle(
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
                  style: const TextStyle(
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
    return Column(
      children: [
        TextFormField(
          controller: nameIndonesianController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Indonesian name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Indonesian name is required'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nameChineseController,
          enabled: enabled,
          decoration: const InputDecoration(
            labelText: 'Chinese name',
            hintText: '中文名',
            prefixIcon: Icon(Icons.translate_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: email,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            helperText: 'Contact support to change your email',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: whatsappController,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'WhatsApp number',
            hintText: '08xxxxxxxxxx',
            prefixIcon: Icon(Icons.chat_outlined),
          ),
        ),
        if (showParentFields &&
            parentNameController != null &&
            parentPhoneController != null) ...[
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Parent / guardian',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Used by staff to contact family when needed.',
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
            decoration: const InputDecoration(
              labelText: 'Parent name',
              prefixIcon: Icon(Icons.family_restroom_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: parentPhoneController,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Parent telephone',
              hintText: '08xxxxxxxxxx',
              prefixIcon: Icon(Icons.phone_outlined),
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
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: level,
          decoration: const InputDecoration(
            labelText: 'HSK level',
            prefixIcon: Icon(Icons.school_outlined),
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
          decoration: const InputDecoration(
            labelText: 'Lessons per term',
            prefixIcon: Icon(Icons.calendar_view_week_outlined),
          ),
          items: AppConstants.termSizes
              .map(
                (size) => DropdownMenuItem(
                  value: size,
                  child: Text('$size lessons per term'),
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
    final joined = user.createdAt == null
        ? '—'
        : DateFormat('d MMM yyyy').format(user.createdAt!);

    return ProfileSectionCard(
      title: 'Account',
      children: [
        ProfileInfoRow(
          label: 'Member since',
          value: joined,
          icon: Icons.calendar_today_outlined,
        ),
        ProfileInfoRow(
          label: 'Status',
          value: user.active ? 'Active' : 'Inactive',
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
          : const Text('Save changes'),
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
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Text('Sign out'),
    );
  }
}
