import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasker/src/core/connectivity/connectivity_notifier.dart';

/// Banner that displays when the app is offline
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityProvider);

    if (connectivityStatus == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    return MaterialBanner(
      backgroundColor: Colors.orange.shade100,
      leading: Icon(Icons.cloud_off, color: Colors.orange.shade900),
      content: Text(
        'You are offline. Changes will sync when reconnected.',
        style: TextStyle(
          color: Colors.orange.shade900,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

/// Small offline indicator icon for app bar
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityProvider);

    if (connectivityStatus == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: 'Offline mode',
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20),
      ),
    );
  }
}
