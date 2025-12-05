import 'package:flutter_test/flutter_test.dart';

import 'package:tasker/src/features/ai/task_suggestions/models/task_suggestion_request.dart';
import 'package:tasker/src/features/ai/task_suggestions/repositories/heuristic_task_suggestion_repository.dart';

void main() {
  final repository = HeuristicTaskSuggestionRepository();

  TaskSuggestionRequest buildRequest({
    List<String> keywords = const <String>[],
    List<String> tasks = const <String>[],
    int desiredCount = 3,
  }) {
    return TaskSuggestionRequest(
      projectId: 'project-1',
      projectName: 'Project Atlas',
      keywords: keywords,
      recentTasks: tasks,
      desiredCount: desiredCount,
      desiredDueDate: DateTime.now().add(const Duration(days: 2)),
    );
  }

  test('generates at most the requested number of suggestions', () async {
    final request = buildRequest(
      keywords: const <String>['design', 'api', 'handoff'],
      desiredCount: 2,
    );

    final suggestions = await repository.generateSuggestions(request);

    expect(suggestions, isNotEmpty);
    expect(suggestions.length, lessThanOrEqualTo(request.desiredCount));
  });

  test('falls back to generic suggestions when context is missing', () async {
    final request = buildRequest(
      keywords: const <String>[],
      tasks: const <String>[],
    );

    final suggestions = await repository.generateSuggestions(request);

    expect(suggestions, isNotEmpty);
    expect(
      suggestions.every((suggestion) => suggestion.title.isNotEmpty),
      isTrue,
    );
  });

  test('propagates due date guidance onto suggestions', () async {
    final desire = DateTime.now().add(const Duration(days: 4));
    final request = TaskSuggestionRequest(
      projectId: 'project-2',
      projectName: 'Velocity',
      desiredDueDate: desire,
      recentTasks: const <String>['Audit mobile onboarding'],
      keywords: const <String>['onboarding'],
      desiredCount: 3,
    );

    final suggestions = await repository.generateSuggestions(request);

    expect(
      suggestions.any(
        (suggestion) => suggestion.recommendedDueDate != null,
      ),
      isTrue,
      reason: 'At least one suggestion should reference an upcoming due date.',
    );
  });
}
