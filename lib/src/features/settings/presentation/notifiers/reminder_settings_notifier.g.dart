// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_settings_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes persisted reminder settings and helper mutations.

@ProviderFor(ReminderSettingsNotifier)
const reminderSettingsProvider = ReminderSettingsNotifierProvider._();

/// Exposes persisted reminder settings and helper mutations.
final class ReminderSettingsNotifierProvider
    extends $NotifierProvider<ReminderSettingsNotifier, ReminderSettings> {
  /// Exposes persisted reminder settings and helper mutations.
  const ReminderSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderSettingsNotifierHash();

  @$internal
  @override
  ReminderSettingsNotifier create() => ReminderSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReminderSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReminderSettings>(value),
    );
  }
}

String _$reminderSettingsNotifierHash() =>
    r'c696216130485c187c1912899cf0bcd71ba8d00e';

/// Exposes persisted reminder settings and helper mutations.

abstract class _$ReminderSettingsNotifier extends $Notifier<ReminderSettings> {
  ReminderSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ReminderSettings, ReminderSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReminderSettings, ReminderSettings>,
              ReminderSettings,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
