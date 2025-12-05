import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/notifiers/auth_notifier.dart';
import '../providers/providers.dart';
import 'quick_action_service.dart';
import '../routing/app_router.dart';
import '../utils/app_logger.dart';

class QuickActionNavigator extends ConsumerStatefulWidget {
  const QuickActionNavigator({super.key, this.child});

  final Widget? child;

  @override
  ConsumerState<QuickActionNavigator> createState() =>
      _QuickActionNavigatorState();
}

class _QuickActionNavigatorState extends ConsumerState<QuickActionNavigator> {
  ProviderSubscription<QuickActionCommand?>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<QuickActionCommand?>(
      quickActionSelectionProvider,
      (previous, next) {
        if (next == null) return;
        _handleAction(next);
      },
    );
  }

  BuildContext? get _routerContext =>
      appRouter.routerDelegate.navigatorKey.currentContext;

  ScaffoldMessengerState? get _messenger {
    final routerContext = _routerContext;
    return ScaffoldMessenger.maybeOf(routerContext ?? context) ??
        (ScaffoldMessenger.maybeOf(context));
  }

  Future<void> _handleAction(QuickActionCommand command) async {
    final router = appRouter;
    final messenger = _messenger;
    final selection = ref.read(quickActionSelectionProvider.notifier);

    try {
      switch (command.type) {
        case QuickActionTypes.quickNote:
          final authState = ref.read(authProvider);
          final user = authState.value;
          if (user == null) {
            messenger?.showSnackBar(
              const SnackBar(content: Text('Sign in to create quick notes.')),
            );
            return;
          }
          final actionSource = command.metadata?['source'] as String?;
          final enableSwitcher =
              actionSource == 'tile' || actionSource == 'notification';
          router.push(
            AppRoutes.stickyNoteEditor,
            extra: {
              'userId': user.id,
              'note': null,
              'enableNoteSwitcher': enableSwitcher,
            },
          );
          break;
        case QuickActionTypes.stickyNotes:
          final authState = ref.read(authProvider);
          final user = authState.value;
          if (user == null) {
            messenger?.showSnackBar(
              const SnackBar(content: Text('Sign in to view sticky notes.')),
            );
            return;
          }
          router.push(AppRoutes.stickyNotes, extra: {'userId': user.id});
          break;
        case QuickActionTypes.mindMaps:
          router.push(AppRoutes.mindMaps);
          break;
        case QuickActionTypes.quickTask:
          router.go(AppRoutes.projects);
          messenger?.showSnackBar(
            const SnackBar(
              content: Text('Use Quick Task plugins from the dashboard.'),
            ),
          );
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Action failed: ${error.toString()}')),
      );
      appLogger.e('Quick action failed', error: error, stackTrace: stackTrace);
    } finally {
      selection.markHandled();
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(quickActionServiceProvider);
    ref.watch(tileActionServiceProvider);
    return widget.child ?? const SizedBox.shrink();
  }
}
