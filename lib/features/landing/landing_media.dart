/// Royalty-free media URLs for the public landing page (Unsplash / YouTube).
///
/// Unsplash IDs were re-checked 2026-10-16 after three earlier IDs started
/// returning 404. If a photo breaks again, swap the ID and check it with
/// `curl -I` before deploying.
abstract final class LandingMedia {
  /// Brush writing a character on paper.
  static const heroBackground =
      'https://images.unsplash.com/photo-1486303954368-398fea0e72cd?auto=format&fit=crop&w=1400&q=80';

  /// Teacher at the front of a classroom of children.
  static const showcaseClassroom =
      'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=900&q=80';

  static const showcaseStudy =
      'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=900&q=80';

  /// Handwriting practice in a character grid. Also shown in place of the
  /// video while [youtubeEmbedId] is empty.
  static const videoPoster =
      'https://images.unsplash.com/photo-1583389409210-0234eee7cdce?auto=format&fit=crop&w=1200&q=80';

  /// YouTube video ID for the See it in action section. Empty hides the
  /// player and shows [videoPoster] instead. The previous ID (`sWqnIyquCbM`)
  /// became unavailable; set this to the centre's own video when there is one.
  static const youtubeEmbedId = '';

  static bool get hasVideo => youtubeEmbedId.isNotEmpty;

  static String get youtubeWatchUrl =>
      'https://www.youtube.com/watch?v=$youtubeEmbedId';

  static String get youtubeEmbedUrl =>
      'https://www.youtube.com/embed/$youtubeEmbedId?rel=0&modestbranding=1';
}
