import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/hsk_paper_draft.dart';
import 'hsk_paper_reader.dart';
import 'paper_image_ops.dart';

/// One unfinished scan in the list.
class PaperDraftInfo {
  const PaperDraftInfo({
    required this.id,
    required this.fileName,
    required this.code,
    required this.level,
    required this.questions,
    required this.toCheck,
    required this.answered,
    required this.byName,
    required this.savedAt,
  });

  final String id;
  final String fileName;
  final String code;
  final int? level;
  final int questions;
  final int toCheck;
  final int answered;
  final String byName;
  final DateTime? savedAt;

  factory PaperDraftInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return PaperDraftInfo(
      id: d.id,
      fileName: m['fileName'] as String? ?? '',
      code: m['code'] as String? ?? '',
      level: (m['level'] as num?)?.toInt(),
      questions: (m['questions'] as num?)?.toInt() ?? 0,
      toCheck: (m['toCheck'] as num?)?.toInt() ?? 0,
      answered: (m['answered'] as num?)?.toInt() ?? 0,
      byName: m['byName'] as String? ?? '',
      savedAt: (m['savedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A draft opened again: what the proofreading screen needs.
class LoadedPaperDraft {
  const LoadedPaperDraft({
    required this.id,
    required this.draft,
    required this.pages,
    required this.pdfBytes,
    required this.fileName,
    required this.edited,
    required this.drawnBoxes,
    required this.readSeconds,
    required this.engine,
  });

  final String id;
  final HskPaperDraft draft;
  final List<PaperPage> pages;
  final Uint8List pdfBytes;
  final String fileName;
  final Set<int> edited;
  final Map<int, List<PixelBox>> drawnBoxes;
  final int readSeconds;
  final String engine;
}

/// Owner 2026-11-24: an unfinished scan is kept as a draft
/// (`paper_drafts/{id}`, the PDF in Storage `paper_drafts/{uid}/{id}.pdf`)
/// and opened again later without reading the paper again: the pages are
/// drawn from the PDF, the questions and boxes come from the draft. Admin
/// only (like scanning).
class PaperDraftService {
  PaperDraftService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('paper_drafts');

  Stream<List<PaperDraftInfo>> watchDrafts() => _col.snapshots().map((s) =>
      s.docs.map(PaperDraftInfo.fromDoc).toList()
        ..sort((a, b) => (b.savedAt ?? DateTime(2000)).compareTo(a.savedAt ?? DateTime(2000))));

  static Map<String, dynamic> _box(PixelBox b) => {'x0': b.x0, 'y0': b.y0, 'x1': b.x1, 'y1': b.y1};
  static PixelBox _unbox(dynamic m) {
    final x = Map<String, dynamic>.from(m as Map);
    int v(String k) => (x[k] as num?)?.toInt() ?? 0;
    return PixelBox(v('x0'), v('y0'), v('x1'), v('y1'));
  }

  static Map<String, dynamic> slotToMap(HskSlot s) => {
        'number': s.number,
        'skill': s.skill,
        'section': s.section,
        'form': s.form,
        'page': s.page,
        'prompt': s.prompt,
        'options': s.options,
        'segments': s.segments,
        'keyword': s.keyword,
        'accepted': s.accepted,
        'pictures': [for (final b in s.pictures) _box(b)],
        'picturePage': s.picturePage,
        'missing': s.missing,
        'unsure': s.unsure,
        'optionsIncomplete': s.optionsIncomplete,
        'checked': s.checked,
        'orderSet': s.orderSet,
        'oddForm': s.oddForm,
        if (s.paperLevel != null) 'paperLevel': s.paperLevel,
        if (s.correctIndex != null) 'correctIndex': s.correctIndex,
      };

  static HskSlot slotFromMap(Map<String, dynamic> m) {
    List<String> strings(String k) => [for (final v in (m[k] as List? ?? const [])) '$v'];
    final s = HskSlot(
      number: (m['number'] as num).toInt(),
      skill: m['skill'] as String? ?? 'reading',
      section: m['section'] as String? ?? '',
      form: m['form'] as String? ?? HskForm.choice,
      page: (m['page'] as num?)?.toInt() ?? 0,
      prompt: m['prompt'] as String? ?? '',
      options: strings('options'),
      segments: strings('segments'),
      keyword: m['keyword'] as String? ?? '',
      accepted: strings('accepted'),
      pictures: [for (final b in (m['pictures'] as List? ?? const [])) _unbox(b)],
      picturePage: (m['picturePage'] as num?)?.toInt() ?? 0,
      missing: m['missing'] == true,
      unsure: m['unsure'] == true,
      optionsIncomplete: m['optionsIncomplete'] == true,
      correctIndex: (m['correctIndex'] as num?)?.toInt(),
    );
    s.checked = m['checked'] == true;
    s.orderSet = m['orderSet'] == true;
    s.oddForm = m['oddForm'] == true;
    s.paperLevel = (m['paperLevel'] as num?)?.toInt();
    return s;
  }

  /// Saves (or updates [id]) and returns the draft id.
  Future<String> save({
    String? id,
    required HskPaperDraft draft,
    required List<PaperPage> pages,
    required Uint8List pdfBytes,
    required String fileName,
    required Set<int> edited,
    required Map<int, List<PixelBox>> drawnBoxes,
    required int readSeconds,
    required String engine,
    required String byName,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
    final ref = id == null ? _col.doc() : _col.doc(id);
    final path = 'paper_drafts/$uid/${ref.id}.pdf';
    if (id == null) {
      await _storage
          .ref(path)
          .putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));
    }
    await ref.set({
      'fileName': fileName,
      'code': draft.code,
      'level': draft.level,
      'title': draft.title,
      'expected': draft.expected,
      'slots': [for (final s in draft.slots) slotToMap(s)],
      'pages': [
        for (final p in pages)
          {
            'number': p.number,
            'width': p.width,
            'height': p.height,
            'boxes': [for (final b in p.pictureBoxes) _box(b)],
          },
      ],
      'drawn': {
        for (final e in drawnBoxes.entries) '${e.key}': [for (final b in e.value) _box(b)],
      },
      'edited': edited.toList(),
      'questions': draft.slots.length,
      'toCheck': draft.flagged.length,
      'answered': draft.slots.where((s) => s.answered && s.form != HskForm.sentenceWithWord).length,
      'readSeconds': readSeconds,
      'engine': engine,
      'byName': byName,
      if (id == null) 'storagePath': path,
      if (id == null) 'createdBy': uid,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  /// Opens a draft: downloads the PDF and draws its pages again (no reading).
  Future<LoadedPaperDraft> load(
    String id, {
    void Function(int page, int count)? onPage,
  }) async {
    final snap = await _col.doc(id).get();
    final m = snap.data();
    if (m == null) throw StateError('Draft not found.');
    final bytes = await _storage.ref(m['storagePath'] as String).getData(60 * 1024 * 1024);
    if (bytes == null) throw StateError('The PDF of this draft is missing.');
    final pageBoxes = <int, List<PixelBox>>{
      for (final p in (m['pages'] as List? ?? const []))
        ((p as Map)['number'] as num).toInt(): [for (final b in (p['boxes'] as List? ?? const [])) _unbox(b)],
    };
    final pages = await HskPaperReader.renderPdf(bytes, boxes: pageBoxes, onPage: onPage);
    final draft = HskPaperDraft(
      code: m['code'] as String? ?? '',
      level: (m['level'] as num?)?.toInt(),
      title: m['title'] as String? ?? '',
      slots: [
        for (final s in (m['slots'] as List? ?? const []))
          slotFromMap(Map<String, dynamic>.from(s as Map)),
      ],
      expected: {
        for (final e in (Map<String, dynamic>.from(m['expected'] as Map? ?? const {})).entries)
          e.key: (e.value as num).toInt(),
      },
    );
    return LoadedPaperDraft(
      id: id,
      draft: draft,
      pages: pages,
      pdfBytes: bytes,
      fileName: m['fileName'] as String? ?? 'paper.pdf',
      edited: {for (final n in (m['edited'] as List? ?? const [])) (n as num).toInt()},
      drawnBoxes: {
        for (final e in (Map<String, dynamic>.from(m['drawn'] as Map? ?? const {})).entries)
          int.parse(e.key): [for (final b in (e.value as List)) _unbox(b)],
      },
      readSeconds: (m['readSeconds'] as num?)?.toInt() ?? 0,
      engine: m['engine'] as String? ?? '',
    );
  }

  Future<void> delete(String id) async {
    final snap = await _col.doc(id).get();
    final path = snap.data()?['storagePath'] as String?;
    if (path != null) {
      try {
        await _storage.ref(path).delete();
      } catch (_) {
        // Already gone.
      }
    }
    await _col.doc(id).delete();
  }
}
