/// Royalty-free media URLs for the public landing page (Unsplash / YouTube).
abstract final class LandingMedia {
  static const heroBackground =
      'https://images.unsplash.com/photo-1546410531-bb4caa6e4248?auto=format&fit=crop&w=1400&q=80';

  static const showcaseClassroom =
      'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=900&q=80';

  static const showcaseStudy =
      'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=900&q=80';

  static const videoPoster =
      'https://images.unsplash.com/photo-1516322625785-d521a42e0013?auto=format&fit=crop&w=1200&q=80';

  /// Short embed — Mandarin / language-learning themed (YouTube).
  static const youtubeEmbedId = 'sWqnIyquCbM';

  static String get youtubeWatchUrl =>
      'https://www.youtube.com/watch?v=$youtubeEmbedId';

  static String get youtubeEmbedUrl =>
      'https://www.youtube.com/embed/$youtubeEmbedId?rel=0&modestbranding=1';
}
