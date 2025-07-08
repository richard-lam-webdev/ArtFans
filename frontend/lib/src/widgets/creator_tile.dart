import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/creator.dart';
import '../providers/subscription_provider.dart';
import '../utils/snackbar_util.dart';

class CreatorTile extends StatefulWidget {
  final Creator creator;
  const CreatorTile({super.key, required this.creator});

  @override
  State<CreatorTile> createState() => _CreatorTileState();
}

class _CreatorTileState extends State<CreatorTile> {
  bool _isLoading = false;

  Future<void> _toggleFollow() async {
    final subProv = context.read<SubscriptionProvider>();
    final id = widget.creator.id;
    final name = widget.creator.username;
    final currentlyFollowed = subProv.isSubscribed(id);

    // Confirmation dialog
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(
                  currentlyFollowed
                      ? 'Se désabonner de $name'
                      : 'S’abonner à $name',
                ),
                content:
                    currentlyFollowed
                        ? const Text(
                          'Êtes-vous sûr de vouloir vous désabonner ?',
                        )
                        : const Column(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentlyFollowed ? Colors.red : null,
                      foregroundColor: currentlyFollowed ? Colors.white : null,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      currentlyFollowed ? 'Se désabonner' : 'Confirmer (30€)',
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!mounted) return;
    if (!confirmed) return;

    setState(() => _isLoading = true);

    final success =
        currentlyFollowed
            ? await subProv.unsubscribeFromCreator(id)
            : await subProv.subscribeToCreator(id);

    if (!mounted) return;

    if (success) {
      // Met à jour le cache et affiche un SnackBar
      subProv.setSubscriptionStatus(id, !currentlyFollowed);
      showCustomSnackBar(
        context,
        currentlyFollowed
            ? 'Vous êtes désabonné de $name'
            : 'Abonnement à $name réussi !',
        type: SnackBarType.success,
      );
    } else {
      showCustomSnackBar(
        context,
        subProv.errorMessage ?? 'Erreur lors de la mise à jour',
        type: SnackBarType.error,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFollowed = context.watch<SubscriptionProvider>().isSubscribed(
      widget.creator.id,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(widget.creator.avatarUrl),
      ),
      title: Text(widget.creator.username),
      trailing:
          _isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : TextButton(
                onPressed: _toggleFollow,
                child: Text(isFollowed ? 'Se désabonner' : 'Suivre'),
              ),
      onTap: () {
        if (mounted) {
          Navigator.of(context).pushNamed('/u/${widget.creator.id}');
        }
      },
    );
  }
}
