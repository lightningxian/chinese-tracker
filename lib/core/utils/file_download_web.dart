import 'dart:convert';
import 'dart:html' as html;

void downloadTextFile(String filename, String content) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
}

/// Opens [bytes] in a new browser tab (a PDF shows in the browser's
/// viewer); the address is a local blob, never a shareable link.
void openBytesInNewTab(List<int> bytes, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Revoked later: the new tab needs a moment to load it.
  Future<void>.delayed(const Duration(minutes: 1), () => html.Url.revokeObjectUrl(url));
}

/// Saves [bytes] as a file named [filename] (a picture, a PDF...).
void downloadBytesFile(String filename, List<int> bytes, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  anchor.remove();
  Future<void>.delayed(const Duration(seconds: 30), () => html.Url.revokeObjectUrl(url));
}
