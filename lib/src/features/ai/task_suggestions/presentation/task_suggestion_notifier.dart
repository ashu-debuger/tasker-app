import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/app_logger.dart';
import '../models/task_suggestion.dart';
import '../models/task_suggestion_request.dart';
import '../repositories/heuristic_task_suggestion_repository.dart';
import '../repositories/task_suggestion_repository.dart';

part 'task_suggestion_notifier.g.dart';

@riverpod
TaskSuggestionRepository taskSuggestionRepository(Ref ref) {
  return const HeuristicTaskSuggestionRepository();
}

/// Async controller that fetches suggestions for a specific context.
@riverpod
class TaskSuggestionController extends _$TaskSuggestionController {
  @override
  FutureOr<List<TaskSuggestion>> build(TaskSuggestionRequest request) async {
    appLogger.d(
      'TaskSuggestionController building projectId=${request.projectId}',
    );
    final repository = ref.watch(taskSuggestionRepositoryProvider);
    return repository.generateSuggestions(request);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(taskSuggestionRepositoryProvider);
      return repository.generateSuggestions(request);
    });
  }
}
