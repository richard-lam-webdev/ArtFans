// lib/src/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/search_provider.dart';
import '../providers/recent_search_provider.dart';
import '../widgets/recent_searches.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: TextField(
          autofocus: true,
          onChanged: context.read<SearchProvider>().onQueryChanged,
          decoration: const InputDecoration(
            hintText: 'Rechercher…',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (search.query.isNotEmpty)
            IconButton(
              tooltip: 'Effacer',
              icon: const Icon(Icons.clear),
              onPressed:
                  () => context.read<SearchProvider>().onQueryChanged(''),
            ),
        ],
      ),
      body: _buildBody(context, search),
    );
  }

  Widget _buildBody(BuildContext context, SearchProvider search) {
    if (search.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (search.error != null) {
      return Center(child: Text('Erreur : ${search.error}'));
    }
    if (search.query.isEmpty) {
      return RecentSearches(
        onSearch: (q) => context.read<SearchProvider>().onQueryChanged(q),
      );
    }
    if (search.creators.isEmpty && search.contents.isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }

    return CustomScrollView(
      slivers: [
        if (search.creators.isNotEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Créateurs', style: TextStyle(fontSize: 18)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => CreatorTile(creator: search.creators[i]),
              childCount: search.creators.length,
            ),
          ),
        ],
        if (search.contents.isNotEmpty) ...[
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Contenus', style: TextStyle(fontSize: 18)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3 / 4,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => ContentCard(content: search.contents[i]),
                childCount: search.contents.length,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets UI (typés Creator & Content)
// ---------------------------------------------------------------------------

class CreatorTile extends StatelessWidget {
  const CreatorTile({Key? key, required this.creator}) : super(key: key);

  final Creator creator;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(creator.avatarUrl)),
      title: Text(creator.username),
      trailing: TextButton(
        onPressed: () {}, // implémenté ailleurs
        child: Text(creator.isFollowed ? 'Abonné' : 'Suivre'),
      ),
      onTap: () => context.push('/u/${creator.id}'),
    );
  }
}

class ContentCard extends StatelessWidget {
  const ContentCard({Key? key, required this.content}) : super(key: key);

  final Content content;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/p/${content.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(content.thumbnailUrl, fit: BoxFit.cover),
          ),
          const SizedBox(height: 4),
          Text(
            content.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '@${content.creatorName}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
