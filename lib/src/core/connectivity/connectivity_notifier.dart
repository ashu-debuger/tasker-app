import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_notifier.g.dart';

/// Connectivity status
enum ConnectivityStatus { online, offline }

/// Notifier to track network connectivity status
@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  ConnectivityStatus build() {
    // Initialize with offline status
    _initialize();
    return ConnectivityStatus.offline;
  }

  Future<void> _initialize() async {
    final connectivity = Connectivity();

    // Check initial connectivity
    final result = await connectivity.checkConnectivity();
    state = _getStatusFromResult(result);

    // Listen to connectivity changes
    _subscription = connectivity.onConnectivityChanged.listen((results) {
      state = _getStatusFromResult(results);
    });

    ref.onDispose(() {
      _subscription.cancel();
    });
  }

  ConnectivityStatus _getStatusFromResult(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    return ConnectivityStatus.online;
  }

  /// Check if currently online
  bool get isOnline => state == ConnectivityStatus.online;

  /// Check if currently offline
  bool get isOffline => state == ConnectivityStatus.offline;
}
