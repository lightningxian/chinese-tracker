import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/exercise.dart';

/// Thumbnails of a question's pictures as the bank shows them: the picture
/// choices (lettered, in order) and/or the question's own picture.
class QuestionPictures extends StatelessWidget {
  const QuestionPictures({super.key, required this.question, this.height = 72});

  final ExerciseQuestion question;
  final double height;

  @override
  Widget build(BuildContext context) {
    final urls = question.optionImageUrls;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (question.imageUrl.isNotEmpty) _thumb(question.imageUrl, null),
        for (var i = 0; i < urls.length; i++)
          if (urls[i].isNotEmpty)
            _thumb(urls[i], String.fromCharCode(65 + i)),
      ],
    );
  }

  Widget _thumb(String url, String? letter) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              height: height,
              width: height * 1.2,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                height: height,
                width: height * 1.2,
                child: Icon(Icons.broken_image_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          if (letter != null)
            Text(
              letter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
        ],
      );
}
