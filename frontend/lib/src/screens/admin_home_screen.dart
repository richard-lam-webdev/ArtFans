import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/admin_content_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../providers/feature_flag_provider.dart';
import '../providers/report_provider.dart';

import '../widgets/bottom_nav.dart';
import '../widgets/admin_dashboard_widgets.dart';

import 'comments_moderation_screen.dart';
import 'reports_moderation_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminStats = context.read<AdminStatsProvider>();
      adminStats.fetchDashboard();
      adminStats.fetchRevenueChart();
      adminStats.fetchTopCreators();
      adminStats.fetchQuickStats();

      context.read<AdminProvider>().fetchUsers();
      context.read<AdminContentProvider>().fetchContents();
      context.read<AdminStatsProvider>().fetchDashboard();
      context.read<FeatureFlagProvider>().loadFeatures();
      context.read<ReportProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Back-office Admin'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Utilisateurs', icon: Icon(Icons.person)),
              Tab(text: 'Contenus', icon: Icon(Icons.article)),
              Tab(text: 'Commentaires', icon: Icon(Icons.comment)),
              Tab(text: 'Signalements', icon: Icon(Icons.flag)),
              Tab(text: 'Fonctionnalités', icon: Icon(Icons.extension)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<AdminProvider>().fetchUsers();
                context.read<AdminContentProvider>().fetchContents();
                context.read<AdminStatsProvider>().refreshAll();
                context.read<FeatureFlagProvider>().loadFeatures();
                context.read<ReportProvider>().fetchReports();
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => auth.logout(),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _UsersTab(),
            _ContentsTab(),
            CommentsModerationScreen(),
            ReportsModerationScreen(),
            _FeaturesTab(),
          ],
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 4),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminStatsProvider>();

    if (prov.status == AdminStatsStatus.loading ||
        prov.status == AdminStatsStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prov.status == AdminStatsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur : ${prov.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => prov.fetchDashboard(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final dashboard = prov.dashboard;
    if (dashboard.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final stats = dashboard['stats'] as Map<String, dynamic>? ?? {};
    final topCreators = dashboard['top_creators'] as List<dynamic>? ?? [];
    final recentRevenue = dashboard['recent_revenue'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PeriodSelector(
            selectedPeriod: prov.selectedPeriod,
            onPeriodChanged: (p) => prov.setPeriod(p),
          ),
          const SizedBox(height: 16),
          KpiGrid(
            stats: stats,
            formatCurrency: prov.formatCurrency,
            formatPercentage: prov.formatPercentage,
            formatNumber: prov.formatNumber,
          ),
          const SizedBox(height: 24),
          if (MediaQuery.of(context).size.width > 800)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: RevenueChart(
                    data: List<Map<String, dynamic>>.from(recentRevenue),
                    title: 'Revenus des 7 derniers jours',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TopCreatorsWidget(
                    creators: List<Map<String, dynamic>>.from(topCreators),
                    title: 'Top 5 Créateurs',
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                RevenueChart(
                  data: List<Map<String, dynamic>>.from(recentRevenue),
                  title: 'Revenus des 7 derniers jours',
                ),
                const SizedBox(height: 16),
                TopCreatorsWidget(
                  creators: List<Map<String, dynamic>>.from(topCreators),
                  title: 'Top 5 Créateurs',
                ),
              ],
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résumé de la période',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    context,
                    'Revenus moyens par utilisateur',
                    prov.formatCurrency(
                      (stats['avg_revenue_per_user'] ?? 0.0).round(),
                    ),
                  ),
                  _buildSummaryRow(
                    context,
                    'Contenus moyens par créateur',
                    (stats['avg_content_per_creator'] ?? 0.0).toStringAsFixed(
                      1,
                    ),
                  ),
                  _buildSummaryRow(
                    context,
                    'Contenus approuvés',
                    '${stats['approved_contents'] ?? 0}',
                  ),
                  _buildSummaryRow(
                    context,
                    'Contenus rejetés',
                    '${stats['rejected_contents'] ?? 0}',
                  ),
                  _buildSummaryRow(
                    context,
                    'Période analysée',
                    '${stats['period'] ?? 'N/A'}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminProvider>();

    if (prov.status == AdminStatus.loading ||
        prov.status == AdminStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.status == AdminStatus.error) {
      return Center(
        child: Text(
          'Erreur : ${prov.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final users = prov.users;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Utilisateur')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Rôle')),
          DataColumn(label: Text('Inscrit le')),
          DataColumn(label: Text('Action')),
        ],
        rows:
            users.map((u) {
              final id = u['ID'] as String;
              final role = u['Role'] as String;
              final createdAt = u['CreatedAt'] as String;
              final isSubscriber = role == 'subscriber';

              return DataRow(
                cells: [
                  DataCell(Text(u['Username'] as String)),
                  DataCell(Text(u['Email'] as String)),
                  DataCell(Text(role)),
                  DataCell(Text(createdAt)),
                  DataCell(
                    isSubscriber
                        ? ElevatedButton(
                          onPressed: () async {
                            try {
                              await context.read<AdminProvider>().updateRole(
                                id,
                                'creator',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Promu en creator !'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },
                          child: const Text('Promouvoir'),
                        )
                        : ElevatedButton(
                          onPressed: () async {
                            try {
                              await context.read<AdminProvider>().updateRole(
                                id,
                                'subscriber',
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rétrogradé en subscriber !'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },
                          child: const Text('Rétrograder'),
                        ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _ContentsTab extends StatelessWidget {
  const _ContentsTab();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AdminContentProvider>();

    if (prov.status == AdminContentStatus.loading ||
        prov.status == AdminContentStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.status == AdminContentStatus.error) {
      return Center(
        child: Text(
          'Erreur : ${prov.errorMessage}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final contents = prov.contents;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Titre')),
          DataColumn(label: Text('Auteur')),
          DataColumn(label: Text('Publié le')),
          DataColumn(label: Text('Statut')),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            contents.map((c) {
              final id = c['ID'] as String? ?? '';
              final title = c['Title'] as String? ?? '';
              final author = c['AuthorID'] as String? ?? '';
              final createdAt = c['CreatedAt'] as String? ?? '';
              final status = c['Status'] as String? ?? 'pending';

              Widget actionCell;
              if (status == 'pending') {
                actionCell = Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => prov.approveContent(id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => prov.rejectContent(id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => prov.deleteContent(id),
                    ),
                  ],
                );
              } else {
                final approved = status == 'approved';
                actionCell = Text(
                  approved ? '✅ Approuvé' : '🚫 Rejeté',
                  style: TextStyle(
                    color: approved ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }

              return DataRow(
                cells: [
                  DataCell(Text(title)),
                  DataCell(Text(author)),
                  DataCell(Text(createdAt)),
                  DataCell(Text(status)),
                  DataCell(actionCell),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _FeaturesTab extends StatelessWidget {
  const _FeaturesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FeatureFlagProvider>(
      builder: (_, prov, __) {
        if (prov.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (prov.error != null) {
          return Center(child: Text('Erreur : ${prov.error}'));
        }
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 600 ? 2 : 1;
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 5,
              ),
              itemCount: prov.features.length,
              itemBuilder: (ctx, i) {
                final f = prov.features[i];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(f.key),
                    subtitle: Text(f.description),
                    trailing: Switch(
                      value: f.enabled,
                      onChanged: (v) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await prov.updateFeature(f.key, v);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Mise à jour réussie'
                                  : 'Erreur de mise à jour',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
