import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feature_flag_provider.dart';
import '../models/feature.dart';

class FeatureGate extends StatelessWidget {
  final String featureKey;
  final WidgetBuilder builder;
  final WidgetBuilder? fallback;

  const FeatureGate({
    required this.featureKey,
    required this.builder,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<FeatureFlagProvider>();
    if (prov.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final f = prov.features.firstWhere(
      (f) => f.key == featureKey,
      orElse: () => Feature(key: featureKey, description: '', enabled: false),
    );
    if (f.enabled) {
      return builder(context);
    }
    return fallback?.call(context) ?? const SizedBox.shrink();
  }
}
