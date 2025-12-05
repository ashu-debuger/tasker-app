// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier for managing chat messages in a project

@ProviderFor(ChatNotifier)
const chatProvider = ChatNotifierFamily._();

/// Notifier for managing chat messages in a project
final class ChatNotifierProvider
    extends $StreamNotifierProvider<ChatNotifier, List<ChatMessage>> {
  /// Notifier for managing chat messages in a project
  const ChatNotifierProvider._({
    required ChatNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatNotifierHash();

  @override
  String toString() {
    return r'chatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatNotifier create() => ChatNotifier();

  @override
  bool operator ==(Object other) {
    return other is ChatNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatNotifierHash() => r'6479e93e6c65d2c7aa29544b5bff6f0d928d3d58';

/// Notifier for managing chat messages in a project

final class ChatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatNotifier,
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>,
          String
        > {
  const ChatNotifierFamily._()
    : super(
        retry: null,
        name: r'chatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier for managing chat messages in a project

  ChatNotifierProvider call(String projectId) =>
      ChatNotifierProvider._(argument: projectId, from: this);

  @override
  String toString() => r'chatProvider';
}

/// Notifier for managing chat messages in a project

abstract class _$ChatNotifier extends $StreamNotifier<List<ChatMessage>> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  Stream<List<ChatMessage>> build(String projectId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
