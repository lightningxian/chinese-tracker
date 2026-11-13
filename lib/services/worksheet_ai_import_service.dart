import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/exercise_authoring_platform.dart';
import '../models/ai_worksheet.dart';
import 'worksheet_import_service.dart';

/// Reads a scanned paper or worksheet with Gemini through Firebase AI Logic
/// (no API key in the app: the Firebase project and App Check gate the
/// calls). The reader returns the questions already typed and keyed where
/// it can, plus the boxes of pictures to cut out; the admin still checks
/// everything on the review screen before it enters the bank.
///
/// Owner setup (once, Firebase console): AI Services → AI Logic → Get
/// started (Gemini Developer API), and App Check registered for the web
/// app (`docs/WORKSHEET_IMPORT.md`).
class WorksheetAiImportService {
  WorksheetAiImportService({GenerativeModel? model}) : _model = model;

  /// Cheapest current model that reads PDFs and returns structured JSON
  /// (`firebase.google.com/docs/ai-logic/models`).
  static const modelName = 'gemini-3.8-flash';

  static const maxBytes = 18 * 1024 * 1024; // AI Logic request limit 20 MB

  GenerativeModel? _model;

  GenerativeModel get model => _model ??= FirebaseAI.googleAI().generativeModel(
        model: modelName,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _schema,
          temperature: 0.1,
          maxOutputTokens: 65536,
        ),
      );

  static String mimeTypeFor(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => '',
    };
  }

  Future<AiWorksheet> read({
    required Uint8List bytes,
    required String fileName,
  }) async {
    ExerciseAuthoringPlatform.ensureWeb();
    final mimeType = mimeTypeFor(fileName);
    if (mimeType.isEmpty) {
      throw WorksheetImportException(
        'Unsupported file type. Use a PDF or a JPG/PNG/WebP image.',
      );
    }
    if (bytes.isEmpty) throw WorksheetImportException('The file is empty.');
    if (bytes.length > maxBytes) {
      throw WorksheetImportException('File is too large. Maximum size is 18 MB.');
    }

    final GenerateContentResponse response;
    try {
      response = await model.generateContent([
        Content.multi([const TextPart(_prompt), InlineDataPart(mimeType, bytes)]),
      ]);
    } on FirebaseAIException catch (e) {
      throw WorksheetImportException(_describe(e));
    }
    final text = response.text?.trim() ?? '';
    if (text.isEmpty) {
      throw WorksheetImportException(
        'The AI reader returned nothing. Try again, or split the file.',
      );
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) throw const FormatException('not an object');
      return AiWorksheet.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException catch (e) {
      debugPrint('AI import: bad JSON: $e');
      throw WorksheetImportException(
        'The AI reader sent an unreadable answer. Try again.',
      );
    }
  }

  static String _describe(FirebaseAIException e) {
    final message = e.message;
    if (e is ServiceApiNotEnabled ||
        message.contains('not enabled') ||
        message.contains('PERMISSION_DENIED') ||
        message.contains('App Check') ||
        message.contains('403')) {
      return 'AI reading is not set up for this project yet: enable AI Logic '
          'and App Check in the Firebase console (docs/WORKSHEET_IMPORT.md). '
          '($message)';
    }
    return 'AI reading failed: $message';
  }

  static const _prompt = '''
You are reading a Chinese language test paper or worksheet (HSK style) for a
teaching centre. Return every question as JSON that follows the schema.

Rules:
- Keep the printed order and numbering. Group questions into sections with
  the printed headings, joined with " · " (for example
  "一、听力 · 第一部分 · 第1-5题"). skill is listening, reading or writing.
- Question types:
  picture_choice: choose a picture (A–F). optionImageBoxes = one tight box per
    picture in letter order; options = the letters. prompt = printed text if
    any, else empty.
  true_false: a ★ statement judged √ or ×. prompt = the statement (and the
    printed text before it, if any). correctIndex 0 = √, 1 = ×.
  choice: options are printed text (A/B/C/D). prompt = the question and any
    passage printed with it.
  matching: choose the lettered sentence that fits. options = the shared
    lettered sentences in letter order, repeated on every question of the
    group; prompt = the question's own sentence.
  cloze: choose the word for the blank. options = the shared word bank in
    letter order, repeated on every question of the group; prompt = the
    sentence with its blank.
  reorder: put the given words in order to make a sentence. segments = the
    words in the CORRECT order when you can solve it, else in printed order.
  write_hanzi: write the character for the pinyin. prompt = the sentence
    with the gap, keyword = the pinyin, accepted = [the character].
  sentence_with_word: write a sentence using the given word (keyword).
- Answer key: when the paper prints a key, use it. Otherwise solve the
  reading and writing questions yourself and set correctIndex (0-based). For
  listening questions with no transcript set correctIndex to -1.
- Examples marked 例如 are not questions: skip them. Skip answer sheets and
  cover pages.
- page is the 1-based page of the file. Boxes are [ymin, xmin, ymax, xmax] on
  a 0–1000 scale of that page. Give imageBox only for a picture that belongs
  to one question; give optionImageBoxes for picture choices.
- Copy Chinese text exactly as printed, with its punctuation. Do not add
  pinyin, translations or questions that are not on the paper.
- code = the paper code printed on it (for example H326202Z), hskLevel = the
  level printed on it (1–6, 0 if unknown), category = hsk_simulation for a
  full HSK paper, exam for a test, else exercise.
''';

  static final _schema = Schema.object(
    properties: {
      'title': Schema.string(description: 'Printed title of the paper'),
      'code': Schema.string(description: 'Printed paper code, or empty'),
      'hskLevel': Schema.integer(description: 'HSK level 1-6, 0 if unknown'),
      'category': Schema.enumString(
        enumValues: ['exercise', 'quiz', 'exam', 'hsk_simulation'],
      ),
      'sections': Schema.array(
        items: Schema.object(
          properties: {
            'title': Schema.string(),
            'skill': Schema.enumString(
              enumValues: ['listening', 'reading', 'writing'],
            ),
            'instructions': Schema.string(),
            'questions': Schema.array(
              items: Schema.object(
                properties: {
                  'number': Schema.integer(),
                  'type': Schema.enumString(enumValues: [
                    'picture_choice',
                    'true_false',
                    'choice',
                    'matching',
                    'cloze',
                    'reorder',
                    'write_hanzi',
                    'sentence_with_word',
                  ]),
                  'page': Schema.integer(),
                  'prompt': Schema.string(),
                  'options': Schema.array(items: Schema.string()),
                  'correctIndex': Schema.integer(
                    description: '0-based, -1 when unknown',
                  ),
                  'segments': Schema.array(items: Schema.string()),
                  'keyword': Schema.string(),
                  'accepted': Schema.array(items: Schema.string()),
                  'imageBox': Schema.array(items: Schema.integer()),
                  'optionImageBoxes': Schema.array(
                    items: Schema.array(items: Schema.integer()),
                  ),
                },
                optionalProperties: [
                  'prompt',
                  'options',
                  'segments',
                  'keyword',
                  'accepted',
                  'imageBox',
                  'optionImageBoxes',
                ],
              ),
            ),
          },
          optionalProperties: ['instructions'],
        ),
      ),
    },
    optionalProperties: ['code', 'hskLevel'],
  );
}
