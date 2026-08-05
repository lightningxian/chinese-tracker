import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../landing_media.dart';

// Web iframe embed (conditional import).
import 'landing_youtube_embed_stub.dart'
    if (dart.library.js_interop) 'landing_youtube_embed_web.dart';

/// Embedded YouTube on web; poster + open-in-browser on other platforms.
class LandingYoutubeEmbed extends StatelessWidget {
  const LandingYoutubeEmbed({super.key, this.height = 320});

  final double height;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: buildYoutubeIframe(LandingMedia.youtubeEmbedUrl),
        ),
      );
    }

    return _PosterWithPlay(height: height);
  }
}

class _PosterWithPlay extends StatelessWidget {
  const _PosterWithPlay({required this.height});

  final double height;

  Future<void> _open() async {
    final uri = Uri.parse(LandingMedia.youtubeWatchUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.black12,
        child: InkWell(
          onTap: _open,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                LandingMedia.videoPoster,
                height: height,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: height,
                  color: Colors.black26,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
