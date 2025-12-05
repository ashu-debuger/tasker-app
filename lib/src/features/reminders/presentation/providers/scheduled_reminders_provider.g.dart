// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_reminders_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that fetches pending notifications and enriches them with task data

@ProviderFor(ScheduledReminders)
const scheduledRemindersProvider = ScheduledRemindersProvider._();

/// Provider that fetches pending notifications and enriches them with task data
final class ScheduledRemindersProvider
    extends
        $AsyncNotifierProvider<ScheduledReminders, List<ScheduledReminder>> {
  /// Provider that fetches pending notifications and enriches them with task data
  const ScheduledRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scheduledRemindersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scheduledRemindersHash();

  @$internal
  @override
  ScheduledReminders create() => ScheduledReminders();
}

String _$scheduledRemindersHash() =>
    r'3cb15325fd8d704076de2db31dcd788b2a7fcf92';

/// Provider that fetches pending notifications and enriches them with task data

abstract class _$ScheduledReminders
    extends $AsyncNotifier<List<ScheduledReminder>> {
  FutureOr<List<ScheduledReminder>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ScheduledReminder>>,
              List<ScheduledReminder>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ScheduledReminder>>,
                List<ScheduledReminder>
              >,
              AsyncValue<List<ScheduledReminder>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
