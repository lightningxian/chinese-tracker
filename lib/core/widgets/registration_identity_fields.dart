import 'package:flutter/material.dart';

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
    return Column(
      children: [
        TextFormField(
          controller: nameIndonesianController,
          enabled: enabled,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
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
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: requireChineseName
                ? 'Chinese name'
                : 'Chinese name (optional)',
            hintText: '中文名',
            prefixIcon: const Icon(Icons.translate_outlined),
          ),
          validator: requireChineseName
              ? (value) => value == null || value.trim().isEmpty
                  ? 'Chinese name is required'
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
                ? 'WhatsApp number'
                : 'WhatsApp number (optional)',
            hintText: '08xxxxxxxxxx',
            prefixIcon: const Icon(Icons.chat_outlined),
          ),
          validator: requireWhatsapp
              ? (value) => value == null || value.trim().isEmpty
                  ? 'WhatsApp number is required'
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
              'Contact details for the student family.',
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: requireParentFields
                  ? 'Parent name'
                  : 'Parent name (optional)',
              prefixIcon: const Icon(Icons.family_restroom_outlined),
            ),
            validator: requireParentFields
                ? (value) => value == null || value.trim().isEmpty
                    ? 'Parent name is required'
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
                  ? 'Parent telephone'
                  : 'Parent telephone (optional)',
              hintText: '08xxxxxxxxxx',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: requireParentFields
                ? (value) => value == null || value.trim().isEmpty
                    ? 'Parent telephone is required'
                    : null
                : null,
          ),
        ],
      ],
    );
  }
}
