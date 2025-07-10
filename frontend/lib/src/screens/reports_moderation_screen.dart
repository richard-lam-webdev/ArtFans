import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/report_provider.dart';
import '../providers/admin_content_provider.dart';
import '../utils/snackbar_util.dart';

class ReportsModerationScreen extends StatelessWidget {
  const ReportsModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProv = context.watch<ReportProvider>();

    // Chargement
    if (reportProv.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // Erreur
    if (reportProv.error != null) {
      return Center(child: Text('Erreur : ${reportProv.error}'));
    }
    // Données
    final reports = reportProv.reports;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Contenu')),
          DataColumn(label: Text('Signalant')),
          DataColumn(label: Text('Raison')),
          DataColumn(label: Text('Signalé')),
          DataColumn(label: Text('Action')),
        ],
        rows:
            reports.map((r) {
              final contentId = r['target_content_id'] as String;
              final reporterId = r['reporter_id'] as String;
              final reason = (r['reason'] as String?) ?? '';
              final createdAt = DateTime.parse(r['created_at'] as String);

              return DataRow(
                cells: [
                  DataCell(Text(contentId)),
                  DataCell(Text(reporterId)),
                  DataCell(Text(reason)),
                  DataCell(Text(timeago.format(createdAt, locale: 'fr'))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed =
                            await showDialog<bool>(
                              context: context,
                              builder:
                                  (ctx) => AlertDialog(
                                    title: const Text('Supprimer le contenu'),
                                    content: const Text(
                                      'Voulez-vous vraiment supprimer ce contenu ?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(ctx).pop(false),
                                        child: const Text('Annuler'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed:
                                            () => Navigator.of(ctx).pop(true),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                            ) ??
                            false;

                        if (!confirmed) return;

                        try {
                          // Supprimer le contenu signalé
                          await context
                              .read<AdminContentProvider>()
                              .deleteContent(contentId);

                          // Raffraîchir la liste des reports
                          await context.read<ReportProvider>().fetchReports();

                          showCustomSnackBar(
                            context,
                            'Contenu supprimé',
                            type: SnackBarType.success,
                          );
                        } catch (e) {
                          showCustomSnackBar(
                            context,
                            'Erreur : $e',
                            type: SnackBarType.error,
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
