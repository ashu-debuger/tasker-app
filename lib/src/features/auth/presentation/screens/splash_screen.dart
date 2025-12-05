import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/notification_permission_state.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/models/app_user.dart';
import '../notifiers/auth_notifier.dart';

/// Splash screen that checks authentication state
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔵 SplashScreen.build() called');

    ref.listen<AsyncValue<AppUser?>>(authProvider, (previous, next) {
      print(
        '🟢 Listener fired - previous.isLoading: ${previous?.isLoading}, previous==null: ${previous == null}',
      );
      print(
        '🟢 Listener fired - next.hasValue: ${next.hasValue}, next.hasError: ${next.hasError}, next.isLoading: ${next.isLoading}',
      );

      // Only navigate when state actually changes from loading to data/error
      if (previous?.isLoading == true || previous == null) {
        print('🟡 Inside navigation condition');

        next.when(
          data: (user) {
            try {
              print(
                '🟠 In data branch - user is ${user == null ? "null" : "not null (${user.id})"}',
              );
              print('🟠 context.mounted: ${context.mounted}');

              if (!context.mounted) {
                print('🔴 Context not mounted, returning');
                return;
              }

              if (user != null) {
                print(
                  '🟠 About to read notificationPermissionStateProvider...',
                );
                final hasAskedPermission = ref.read(
                  notificationPermissionStateProvider,
                );
                print('🟠 hasAskedPermission: $hasAskedPermission');

                if (!hasAskedPermission) {
                  print(
                    '🚀 Navigating to: ${AppRoutes.notificationPermission}',
                  );
                  context.go(AppRoutes.notificationPermission);
                  print(
                    '✅ Navigation call completed for notificationPermission',
                  );
                } else {
                  print('🚀 Navigating to: ${AppRoutes.projects}');
                  context.go(AppRoutes.projects);
                  print('✅ Navigation call completed for projects');
                }
              } else {
                print('🚀 Navigating to: ${AppRoutes.signIn}');
                context.go(AppRoutes.signIn);
                print('✅ Navigation call completed for signIn');
              }
            } catch (e, stack) {
              print('💥 EXCEPTION in data branch: $e');
              print('💥 Stack trace: $stack');
            }
          },
          loading: () {
            print('⏳ In loading branch');
          },
          error: (error, stack) {
            print('❌ In error branch: $error');
            if (!context.mounted) {
              print('🔴 Context not mounted in error, returning');
              return;
            }
            print('🚀 Navigating to: ${AppRoutes.signIn} (from error)');
            context.go(AppRoutes.signIn);
            print('✅ Navigation call completed for signIn (from error)');
          },
        );
      } else {
        print('🔴 Navigation condition NOT met - skipping navigation');
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Tasker',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
