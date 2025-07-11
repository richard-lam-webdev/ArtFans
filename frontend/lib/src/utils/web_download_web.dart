import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileWeb(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Crée un <a> invisible
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  // Ajoute-le au DOM, clique dessus, puis supprime-le
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // Libère l’URL après un petit délai
  Future.delayed(const Duration(milliseconds: 100), () {
    html.Url.revokeObjectUrl(url);
  });
}
