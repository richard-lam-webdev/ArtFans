import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/message_provider.dart';
import '../widgets/feature_gate.dart';
import '../constants/features.dart';
import '../widgets/bottom_nav.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureKey: featureChat,
      fallback:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Messages'), centerTitle: true),
            body: const Center(child: Text('La messagerie est désactivée')),
            bottomNavigationBar: const BottomNav(currentIndex: 3),
          ),
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text('Messages'), centerTitle: true),
            body: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                final theme = Theme.of(context);
                final currentUserId = messageProvider.currentUserId;
                if (currentUserId == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messageProvider.isLoading &&
                    messageProvider.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messageProvider.conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface.withAlpha(
                            (0.3 * 255).round(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune conversation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.6 * 255).round(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez à discuter avec d\'autres utilisateurs',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(
                              (0.5 * 255).round(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => messageProvider.refreshConversations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messageProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = messageProvider.conversations[index];
                      final isMyMessage =
                          conversation.lastMessageSender == currentUserId;
                      final hasUnread = messageProvider.hasUnreadMessages(
                        conversation.otherUserId,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            context.push(
                              '/chat/${conversation.otherUserId}',
                              extra: conversation.otherUserName,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      child: Text(
                                        conversation.otherUserName[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.colorScheme.surface,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            conversation.otherUserName,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      hasUnread
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                ),
                                          ),
                                          Text(
                                            timeago.format(
                                              conversation.lastMessageTime,
                                              locale: 'fr',
                                            ),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withAlpha(
                                                        (0.6 * 255).round(),
                                                      ),
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (isMyMessage) ...[
                                            Icon(
                                              Icons.reply,
                                              size: 16,
                                              color: theme.colorScheme.onSurface
                                                  .withAlpha(
                                                    (0.6 * 255).round(),
                                                  ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                          Expanded(
                                            child: Text(
                                              conversation.lastMessage,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withAlpha(
                                                          (0.7 * 255).round(),
                                                        ),
                                                    fontWeight:
                                                        hasUnread
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.onSurface.withAlpha(
                                    (0.4 * 255).round(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            bottomNavigationBar: const BottomNav(currentIndex: 3),
          ),
    );
  }
}
