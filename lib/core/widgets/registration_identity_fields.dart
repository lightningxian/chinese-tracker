import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// Shared identity fields used on registration and complete-profile.
class RegistrationIdentityFields extends StatelessWidget {
  const RegistrationIdentityFields({
    super.key,
    required this.nameIndonesianController,
    required this.nameChineseController,
    required this.whatsappController,
    required this.enabled,
    this.showParentFields = false,
    this.parentNameController,
    this.parentPhoneController,
    this.requireChineseName = false,
    this.requireWhatsapp = true,
    this.requireParentFields = false,
  });

  final TextEditingController nameIndonesianController;
  final TextEditingController nameChineseController;
  final TextEditingController whatsappController;
  final bool enabled;
  final bool showParentFields;
  final TextEditingController? parentNameController;
  final TextEditingController? parentPhoneController;
  final bool requireChineseName;
  final bool requireWhatsapp;
  final bool requireParentFields;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      children: [
        TextFormField(
          controller: nameIndonesianController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
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
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: requireChineseName
                ? l.identityNameChinese
                : l.identityNameChineseOptional,
            hintText: '中文名',
            prefixIcon: const Icon(Icons.translate_outlined),
          ),
          validator: requireChineseName
              ? (value) => value == null || value.trim().isEmpty
                  ? l.identityNameChineseRequired
                  : null
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: whatsappController,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: requireWhatsapp
                ? l.identityWhatsapp
                : l.identityWhatsappOptional,
            hintText: '08xxxxxxxxxx',
            prefixIcon: const Icon(Icons.chat_outlined),
          ),
          validator: requireWhatsapp
              ? (value) => value == null || value.trim().isEmpty
                  ? l.identityWhatsappRequired
                  : null
              : null,
        ),
        if (showParentFields &&
            parentNameController != null &&
            parentPhoneController != null) ...[
          const SizedBox(height: 20),
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
              l.identityParentSectionHint,
              style: const TextStyle(
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: requireParentFields
                  ? l.identityParentName
                  : l.identityParentNameOptional,
              prefixIcon: const Icon(Icons.family_restroom_outlined),
            ),
            validator: requireParentFields
                ? (value) => value == null || value.trim().isEmpty
                    ? l.identityParentNameRequired
                    : null
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: parentPhoneController,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: requireParentFields
                  ? l.identityParentPhone
                  : l.identityParentPhoneOptional,
              hintText: '08xxxxxxxxxx',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: requireParentFields
                ? (value) => value == null || value.trim().isEmpty
                    ? l.identityParentPhoneRequired
                    : null
                : null,
          ),
        ],
      ],
    );
  }
}
