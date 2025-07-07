// lib/src/widgets/admin_dashboard_widgets.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget pour afficher une carte KPI
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? trend;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = Colors.blue,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (trend != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend!,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour le sélecteur de période
class PeriodSelector extends StatelessWidget {
  final int selectedPeriod;
  final Function(int) onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'label': '7j', 'value': 7},
      {'label': '30j', 'value': 30},
      {'label': '90j', 'value': 90},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: periods.map((period) {
                final isSelected = selectedPeriod == period['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(period['label'] as String),
                    selected: isSelected,
                    onSelected: (_) => onPeriodChanged(period['value'] as int),
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour le graphique des revenus
class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const RevenueChart({
    super.key,
    required this.data,
    this.title = 'Revenus des 7 derniers jours',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text('Aucune donnée disponible'),
          ),
        ),
      );
    }

    final spots = data.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final amount = (entry.value['amount'] as int) / 100; // Convertir centimes en euros
      return FlSpot(index, amount);
    }).toList();

    final maxY = data.isNotEmpty 
        ? data.map((d) => (d['amount'] as int) / 100).reduce((a, b) => a > b ? a : b) * 1.2
        : 100.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}€',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final date = DateTime.parse(data[index]['date']);
                            return Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour le classement des créateurs
class TopCreatorsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> creators;
  final String title;

  const TopCreatorsWidget({
    super.key,
    required this.creators,
    this.title = 'Top Créateurs',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (creators.isEmpty)
              const Center(
                child: Text('Aucun créateur trouvé'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: creators.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final creator = creators[index];
                  final rank = creator['rank'] as int;
                  final username = creator['username'] as String;
                  final contentCount = creator['content_count'] as int;
                  final revenue = creator['total_revenue'] as int;
                  final subscribers = creator['subscribers'] as int;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(rank),
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      username,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('$contentCount contenus • $subscribers abonnés'),
                    trailing: Text(
                      '${(revenue / 100).toStringAsFixed(0)}€',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }
}

/// Widget pour une grille de KPI
class KpiGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String Function(int) formatCurrency;
  final String Function(double) formatPercentage;
  final String Function(int) formatNumber;

  const KpiGrid({
    super.key,
    required this.stats,
    required this.formatCurrency,
    required this.formatPercentage,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _getCrossAxisCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        KpiCard(
          title: 'Utilisateurs Total',
          value: formatNumber(stats['total_users'] ?? 0),
          icon: Icons.people,
          color: Colors.blue,
        ),
        KpiCard(
          title: 'Créateurs Actifs',
          value: formatNumber(stats['total_creators'] ?? 0),
          icon: Icons.person_add,
          color: Colors.green,
        ),
        KpiCard(
          title: 'Revenus Total',
          value: formatCurrency(stats['total_revenue'] ?? 0),
          icon: Icons.euro,
          color: Colors.orange,
        ),
        KpiCard(
          title: 'Contenus',
          value: formatNumber(stats['total_contents'] ?? 0),
          subtitle: '${stats['pending_contents'] ?? 0} en attente',
          icon: Icons.article,
          color: Colors.purple,
        ),
        KpiCard(
          title: 'Abonnés',
          value: formatNumber(stats['total_subscribers'] ?? 0),
          icon: Icons.star,
          color: Colors.teal,
        ),
        KpiCard(
          title: 'Taux Conversion',
          value: formatPercentage(stats['conversion_rate'] ?? 0.0),
          icon: Icons.trending_up,
          color: Colors.red,
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }
}