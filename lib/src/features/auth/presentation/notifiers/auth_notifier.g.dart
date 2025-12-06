// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Authentication state notifier
/// Manages user authentication state using StreamNotifier

@ProviderFor(AuthNotifier)
const authProvider = AuthNotifierProvider._();

/// Authentication state notifier
/// Manages user authentication state using StreamNotifier
final class AuthNotifierProvider
    extends $StreamNotifierProvider<AuthNotifier, AppUser?> {
  /// Authentication state notifier
  /// Manages user authentication state using StreamNotifier
  const AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'0231643ffbb28cb6cbd5dadd0459c10d4d2d2305';

/// Authentication state notifier
/// Manages user authentication state using StreamNotifier

abstract class _$AuthNotifier extends $StreamNotifier<AppUser?> {
  Stream<AppUser?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AppUser?>, AppUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppUser?>, AppUser?>,
              AsyncValue<AppUser?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
