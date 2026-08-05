import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

bool _youtubeFactoryRegistered = false;

Widget buildYoutubeIframe(String embedUrl) {
  const viewType = 'landing-youtube-embed';
  if (!_youtubeFactoryRegistered) {
    _youtubeFactoryRegistered = true;
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => web.HTMLIFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture'
        ..allowFullscreen = true,
    );
  }
  return const HtmlElementView(viewType: viewType);
}
