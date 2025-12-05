// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_permission_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks whether the user has been asked for notification permissions

@ProviderFor(NotificationPermissionState)
const notificationPermissionStateProvider =
    NotificationPermissionStateProvider._();

/// Tracks whether the user has been asked for notification permissions
final class NotificationPermissionStateProvider
    extends $NotifierProvider<NotificationPermissionState, bool> {
  /// Tracks whether the user has been asked for notification permissions
  const NotificationPermissionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionStateHash();

  @$internal
  @override
  NotificationPermissionState create() => NotificationPermissionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$notificationPermissionStateHash() =>
    r'c3b1ddb28de8520acb5dc12a04e19c333d0a4c0a';

/// Tracks whether the user has been asked for notification permissions

abstract class _$NotificationPermissionState extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
