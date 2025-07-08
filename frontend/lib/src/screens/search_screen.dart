import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/search_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/snackbar_util.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final token = ctx.read<AuthProvider>().token!;
        return SearchProvider(token: token);
      },
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatelessWidget {
  const _SearchView();

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
      return const Center(child: Text('Entrez un terme pour rechercher'));
    }
    if (search.creators.isEmpty && search.contents.isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }

    return CustomScrollView(
      slivers: [
        if (search.creators.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Créateurs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        if (search.creators.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => CreatorTile(creator: search.creators[index]),
              childCount: search.creators.length,
            ),
          ),
        if (search.contents.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Contenus',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        if (search.contents.isNotEmpty)
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
                (context, index) =>
                    ContentCard(content: search.contents[index]),
                childCount: search.contents.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets UI
// ---------------------------------------------------------------------------

class CreatorTile extends StatefulWidget {
  const CreatorTile({super.key, required this.creator});

  final Creator creator;

  @override
  State<CreatorTile> createState() => _CreatorTileState();
}

class _CreatorTileState extends State<CreatorTile> {
  late bool _isFollowed;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.creator.isFollowed;
  }

  Future<void> _onTapFollow() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final name = widget.creator.username;

    setState(() => _loading = true);

    try {
      if (_isFollowed) {
        // confirmation désabonnement
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: Text('Se désabonner de $name'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir vous désabonner ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Se désabonner'),
                      ),
                    ],
                  ),
            ) ??
            false;

        if (!confirmed) return;
        if (!mounted) return;

        final ok = await subscriptionProvider.unsubscribeFromCreator(
          widget.creator.id,
        );
        if (!mounted) return;

        if (ok) {
          showCustomSnackBar(
            context,
            'Vous êtes désabonné de $name',
            type: SnackBarType.success,
          );
          setState(() => _isFollowed = false);
        } else {
          showCustomSnackBar(
            context,
            subscriptionProvider.errorMessage ?? 'Erreur désabonnement',
            type: SnackBarType.error,
          );
        }
      } else {
        // confirmation abonnement
        final confirmed =
            await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: Text('S\'abonner à $name'),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prix : 30€ / mois'),
                        SizedBox(height: 8),
                        Text('Durée : 30 jours'),
                        SizedBox(height: 16),
                        Text('Confirmez-vous votre abonnement ?'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Confirmer (30€)'),
                      ),
                    ],
                  ),
            ) ??
            false;

        if (!confirmed) return;
        if (!mounted) return;

        final ok = await subscriptionProvider.subscribeToCreator(
          widget.creator.id,
        );
        if (!mounted) return;

        if (ok) {
          showCustomSnackBar(
            context,
            'Abonnement à $name réussi ! (30€)',
            type: SnackBarType.success,
          );
          setState(() => _isFollowed = true);
        } else {
          showCustomSnackBar(
            context,
            subscriptionProvider.errorMessage ?? 'Erreur abonnement',
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Erreur : $e', type: SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.creator.avatarUrl),
      ),
      title: Text(widget.creator.username),
      trailing:
          _loading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : TextButton(
                onPressed: _onTapFollow,
                child: Text(_isFollowed ? 'Se désabonner' : 'Suivre'),
              ),
      onTap: () => context.push('/u/${widget.creator.id}'),
    );
  }
}

class ContentCard extends StatelessWidget {
  const ContentCard({super.key, required this.content});
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
