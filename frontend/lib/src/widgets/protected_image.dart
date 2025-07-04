// lib/widgets/protected_image.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/content_service.dart';

class ProtectedImage extends StatefulWidget {
  final String contentId;
  final bool isSubscribed;

  const ProtectedImage({
    super.key,
    required this.contentId,
    required this.isSubscribed,
  });

  @override
  State<ProtectedImage> createState() => _ProtectedImageState();
}

class _ProtectedImageState extends State<ProtectedImage> {
  final _svc = ContentService();
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProtectedImage old) {
    super.didUpdateWidget(old);
    if (old.isSubscribed != widget.isSubscribed) {
      _load();
    }
  }

  void _load() {
    _imageFuture = _svc.fetchProtectedImage(widget.contentId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text("Erreur image")),
          );
        }
        return SizedBox(
          height: 200,
          child: Image.memory(
            snap.data!,
            fit: BoxFit.cover,
            // plus besoin de Key ici si on l’a déjà mis sur le widget parent
          ),
        );
      },
    );
  }
}
