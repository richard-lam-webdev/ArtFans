// lib/src/utils/web_download_web.dart
import 'dart:typed_data';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Implémentation Web réelle
void downloadFileWeb(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Nettoyer après un délai
  Future.delayed(const Duration(milliseconds: 100), () {
    html.Url.revokeObjectUrl(url);
  });
}