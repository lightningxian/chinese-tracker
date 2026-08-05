import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/shell_nested_page.dart';
import '../../models/material_item.dart';
import '../../services/firestore_service.dart';
import '../../services/materials_storage_service.dart';

/// Shared teaching materials. Staff (embedded=true, readOnly=false) get full
/// CRUD + upload; students/parents (readOnly=true) see only published items.
class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({
    super.key,
    required this.ownerId,
    this.embedded = false,
    this.readOnly = false,
  });

  final String ownerId;
  final bool embedded;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final stream = readOnly
        ? firestore.watchPublishedMaterials(ownerId)
        : firestore.watchMaterials(ownerId);

    return ShellNestedPage(
      embedded: embedded,
      title: 'Materials',
      floatingActionButton: readOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ownerId: ownerId),
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.add),
              label: const Text('Add material'),
            ),
      child: StreamBuilder<List<MaterialItem>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const <MaterialItem>[];
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No materials yet',
              subtitle: readOnly
                  ? 'Published materials from your teacher will appear here.'
                  : 'Tap "Add material" to upload a file or add a resource.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(20, 20, 20, readOnly ? 20 : 96),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MaterialCard(
              item: items[i],
              readOnly: readOnly,
              onEdit: readOnly
                  ? null
                  : () => _openEditor(context, ownerId: ownerId, item: items[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    required String ownerId,
    MaterialItem? item,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MaterialEditorSheet(ownerId: ownerId, item: item),
    );
  }
}

Future<void> _openMaterial(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the file.')),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.item,
    required this.readOnly,
    this.onEdit,
  });

  final MaterialItem item;
  final bool readOnly;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.level != null && item.level!.isNotEmpty) item.level!,
      if (item.skill != null && item.skill!.isNotEmpty) item.skill!,
      ...item.tags,
    ].join(' · ');

    return AppCard(
      onTap: item.fileUrl != null
          ? () => _openMaterial(context, item.fileUrl!)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(item.fileType), color: AppColors.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!readOnly) _StatusPill(published: item.isPublished),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              meta,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (item.fileName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_file,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.fileName!,
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (!readOnly && onEdit != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String? type) {
    return switch (type) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'xls' || 'xlsx' || 'csv' => Icons.table_chart_outlined,
      'mp3' => Icons.audiotrack_outlined,
      'mp4' => Icons.movie_outlined,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.published});

  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? AppColors.success : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        published ? 'Published' : 'Draft',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MaterialEditorSheet extends StatefulWidget {
  const _MaterialEditorSheet({required this.ownerId, this.item});

  final String ownerId;
  final MaterialItem? item;

  @override
  State<_MaterialEditorSheet> createState() => _MaterialEditorSheetState();
}

class _MaterialEditorSheetState extends State<_MaterialEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _levelController;
  late final TextEditingController _skillController;
  late final TextEditingController _tagsController;
  bool _published = false;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  String? _fileUrl;
  String? _fileName;
  String? _fileType;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _levelController = TextEditingController(text: item?.level ?? '');
    _skillController = TextEditingController(text: item?.skill ?? '');
    _tagsController =
        TextEditingController(text: (item?.tags ?? const []).join(', '));
    _published = item?.isPublished ?? false;
    _fileUrl = item?.fileUrl;
    _fileName = item?.fileName;
    _fileType = item?.fileType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _levelController.dispose();
    _skillController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final upload = await context
          .read<MaterialsStorageService>()
          .pickAndUpload(widget.ownerId);
      setState(() {
        _fileUrl = upload.fileUrl;
        _fileName = upload.fileName;
        _fileType = upload.fileType;
      });
    } on MaterialUploadCancelledException {
      // no-op
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final firestore = context.read<FirestoreService>();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final material = MaterialItem(
      id: widget.item?.id ?? '',
      ownerId: widget.ownerId,
      title: _titleController.text.trim(),
      status: _published ? 'published' : 'draft',
      level: _levelController.text.trim(),
      skill: _skillController.text.trim(),
      tags: tags,
      fileUrl: _fileUrl,
      fileName: _fileName,
      fileType: _fileType,
    );
    try {
      if (_isEditing) {
        await firestore.updateMaterial(material);
      } else {
        await firestore.createMaterial(material);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete material?'),
        content: Text('Delete "${widget.item!.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await context.read<FirestoreService>().deleteMaterial(widget.item!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit material' : 'Add material',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error)),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _levelController,
                      decoration: const InputDecoration(
                        labelText: 'Level (optional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: const InputDecoration(
                        labelText: 'Skill (optional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickFile,
                icon: _uploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _fileName != null ? 'Replace file' : 'Upload file (optional)',
                ),
              ),
              if (_fileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _fileName!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _published,
                onChanged: (v) => setState(() => _published = v),
                title: const Text('Published'),
                subtitle: const Text(
                  'Visible to students and parents.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Add material'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: const Text('Delete',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
