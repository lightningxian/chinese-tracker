import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/question_import_utils.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/l10n.dart';
import '../../models/question_bank_item.dart';
import '../../services/firestore_service.dart';
import '../../services/hsk_paper/hsk_paper_reader.dart';
import '../../services/listening/transcriber.dart';
import '../../services/question_bank_media_service.dart';
import '../../core/widgets/discard_guard.dart';

/// The **Transcript** of a worksheet's recording (Build 1B): typed or
/// pasted, read from the official listening script (PDF or image) with
/// the built-in reader, or written from the recording itself (owner
/// 2026-11-24, Q7: speech recognition in the browser). Stored with the worksheet in the bank (students
/// cannot read it); students receive it in the review after the session.
/// Teachers see it here, read-only.
class SheetTranscriptCard extends StatelessWidget {
  const SheetTranscriptCard({
    super.key,
    required this.sheet,
    required this.readOnly,
  });

  final QuestionBankSheet sheet;
  final bool readOnly;

  Future<void> _edit(BuildContext context) async {
    final l = context.l10n;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _TranscriptDialog(
        initial: sheet.transcript ?? '',
        audioUrl: _recordingUrl,
      ),
    );
    if (text == null || !context.mounted) return;
    await context.read<FirestoreService>().setQuestionBankTranscript(
          sheet.items.map((i) => i.id),
          text,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.paperTranscriptSaved)),
      );
    }
  }

  /// The worksheet's listening recording, if one was uploaded.
  String? get _recordingUrl {
    for (final item in sheet.items) {
      final url = item.sectionAudioUrl;
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final transcript = sheet.transcript;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.subject, color: AppColors.navy),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.paperTranscript,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              if (!readOnly)
                OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(transcript == null
                      ? l.paperTranscriptAdd
                      : l.paperTranscriptEdit),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (transcript == null)
            Text(
              l.paperTranscriptNone,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: SelectableText(
                  transcript,
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TranscriptDialog extends StatefulWidget {
  const _TranscriptDialog({required this.initial, this.audioUrl});

  final String initial;
  final String? audioUrl;

  @override
  State<_TranscriptDialog> createState() => _TranscriptDialogState();
}

class _TranscriptDialogState extends State<_TranscriptDialog> {
  late final _text = TextEditingController(text: widget.initial);
  bool _reading = false;
  String _progress = '';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Writes the script from the worksheet's recording, or from an audio
  /// file the admin picks when the worksheet has none (owner 2026-11-24).
  Future<void> _fromRecording() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    Uint8List? bytes;
    final url = widget.audioUrl;
    if (url == null) {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: QuestionBankMediaService.audioExtensions,
        withData: true,
      );
      bytes = picked?.files.firstOrNull?.bytes;
      if (bytes == null) return;
    }
    setState(() {
      _reading = true;
      _progress = l.transcribeLoading(0);
    });
    try {
      final text = await ListeningTranscriber.transcribe(
        url: url,
        bytes: bytes,
        onProgress: (stage, f) {
          if (!mounted) return;
          final pct = (f * 100).round();
          setState(() => _progress =
              stage == 'loading' ? l.transcribeLoading(pct) : l.transcribeWriting(pct));
        },
      );
      final current = _text.text.trim();
      _text.text = current.isEmpty ? text : '$current\n\n$text';
      messenger.showSnackBar(SnackBar(content: Text(l.transcribeDone)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.paperReadFailed('$e'))));
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  /// Reads the official listening script with the built-in reader.
  Future<void> _readFile() async {
    final l = context.l10n;
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _reading = true;
      _progress = l.paperOpening;
    });
    try {
      final reader = HskPaperReader();
      final texts = <String>[];
      if (file.name.toLowerCase().endsWith('.pdf')) {
        final pages = await reader.readPdf(
          bytes,
          onProgress: (_, page, count) {
            if (mounted) {
              setState(() => _progress = l.paperReadingPage(page, count));
            }
          },
        );
        texts.addAll(pages.map((p) => p.text));
      } else {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) throw StateError(l.worksheetCouldNotReadFile);
        final rgba = decoded.convert(numChannels: 4);
        final page = await reader.readPage(
          RgbaPage(rgba.width, rgba.height,
              Uint8List.fromList(rgba.getBytes(order: img.ChannelOrder.rgba))),
          number: 1,
        );
        texts.add(page.text);
      }
      final read = texts
          .map((t) => t
              .split('\n')
              .map((line) => QuestionImportUtils.joinCjkSpaces(line.trim()))
              .where((line) => line.isNotEmpty)
              .join('\n'))
          .join('\n\n');
      final current = _text.text.trim();
      _text.text = current.isEmpty ? read : '$current\n\n$read';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.paperReadFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      DiscardGuard(isDirty: () => !_reading && _text.text != widget.initial, child: _buildEditor(context));

  Widget _buildEditor(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.paperTranscript),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.paperTranscriptHint,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: TextField(
                controller: _text,
                minLines: 8,
                maxLines: 18,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (ListeningTranscriber.available)
                  FilledButton.tonalIcon(
                    onPressed: _reading ? null : _fromRecording,
                    icon: const Icon(Icons.graphic_eq, size: 18),
                    label: Text(widget.audioUrl == null
                        ? l.transcribeFromFile
                        : l.transcribeFromRecording),
                  ),
                OutlinedButton.icon(
                  onPressed: _reading ? null : _readFile,
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: Text(l.paperTranscriptReadFile),
                ),
              ],
            ),
            if (_reading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 4),
              Text(_progress, style: TextStyle(color: AppColors.textSecondary)),
            ],
            if (ListeningTranscriber.available) ...[
              const SizedBox(height: 6),
              Text(l.transcribeNote,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.maybePop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: _reading ? null : () => Navigator.pop(context, _text.text),
          child: Text(l.testsSave),
        ),
      ],
    );
  }
}
