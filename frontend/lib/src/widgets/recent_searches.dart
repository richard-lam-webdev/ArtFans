// lib/src/widgets/recent_searches.dart
import 'package:flutter/material.dart';
import '../providers/recent_search_provider.dart';

class RecentSearches extends StatefulWidget {
  final void Function(String) onSearch;
  const RecentSearches({super.key, required this.onSearch});

  @override
  _RecentSearchesState createState() => _RecentSearchesState();
}

class _RecentSearchesState extends State<RecentSearches> {
  final _repo = RecentSearchProvider();
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.all();
  }

  void _clear() async {
    await _repo.clear();
    setState(() => _future = _repo.all());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (ctx, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('Pas d’historique'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recherches récentes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(onPressed: _clear, child: const Text('Effacer')),
                ],
              ),
            ),
            ...items.map(
              (q) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(q),
                onTap: () => widget.onSearch(q),
              ),
            ),
          ],
        );
      },
    );
  }
}
