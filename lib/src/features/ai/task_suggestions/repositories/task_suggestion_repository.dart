import '../models/task_suggestion.dart';
import '../models/task_suggestion_request.dart';

/// Abstraction for generating AI-based task suggestions.
abstract class TaskSuggestionRepository {
  Future<List<TaskSuggestion>> generateSuggestions(
    TaskSuggestionRequest request,
  );
}
