// lib/widgets/app_wrapper.dart

import 'package:flutter/material.dart';
import 'package:frontend/src/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/message_provider.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;
  
  const AppWrapper({super.key, required this.child});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isInitialized = false;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final messageProvider = context.read<MessageProvider>();
      
      authProvider.addListener(() async {
        if (authProvider.status == AuthStatus.authenticated) {
          // Récupérer l'ID de l'utilisateur actuel
          final currentUserId = await AuthService().getUserId();
          
          // Si c'est un nouvel utilisateur ou première connexion
          if (!_isInitialized || _lastUserId != currentUserId) {
            await messageProvider.initialize();
            debugPrint('### currentUserId = $currentUserId');  
            messageProvider.startAutoRefresh();
            messageProvider.refreshConversations();
            setState(() {
              _isInitialized = true;
              _lastUserId = currentUserId;
            });
          }
        } else if (authProvider.status != AuthStatus.authenticated && _isInitialized) {
          messageProvider.stopAutoRefresh();
          setState(() {
            _isInitialized = false;
            _lastUserId = null;
          });
        }
      });
      
      if (authProvider.status == AuthStatus.authenticated && !_isInitialized) {
        final currentUserId = await AuthService().getUserId();
        debugPrint('### currentUserId = $currentUserId');  
        await messageProvider.initialize();
        messageProvider.startAutoRefresh();
        messageProvider.refreshConversations();
        setState(() {
          _isInitialized = true;
          _lastUserId = currentUserId;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}