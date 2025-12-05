import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/providers/notification_permission_state.dart';

/// Screen to request notification permissions on first launch
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);

    try {
      final notificationService = NotificationService();
      final granted = await notificationService.requestPermissions();

      // Mark that we've asked
      ref.read(notificationPermissionStateProvider.notifier).markAsAsked();

      if (!mounted) return;

      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled! You\'ll receive task reminders.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.projects);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied. You can enable it later in settings.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        // Still allow user to proceed
        context.go(AppRoutes.projects);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permissions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _skipForNow() {
    // Mark that we've asked even if they skip
    ref.read(notificationPermissionStateProvider.notifier).markAsAsked();
    context.go(AppRoutes.projects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                size: 120,
                color: Color(0xFF6750A4),
              ),
              const SizedBox(height: 32),
              Text(
                'Stay on Track with Reminders',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Enable notifications to receive timely reminders for your tasks and routines. '
                'You\'ll never miss an important deadline!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        Icons.alarm,
                        'Task Reminders',
                        'Get notified before your tasks are due',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow(
                        Icons.repeat,
                        'Routine Alerts',
                        'Stay consistent with daily routine reminders',
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureRow(
                        Icons.calendar_today,
                        'Smart Scheduling',
                        'Customizable lead times for each reminder',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isRequesting ? null : _requestPermissions,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Enable Notifications'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isRequesting ? null : _skipForNow,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6750A4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6750A4)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
