import 'package:equatable/equatable.dart';

/// Represents a single AI-generated task suggestion.
class TaskSuggestion extends Equatable {
  const TaskSuggestion({
    required this.title,
    required this.description,
    required this.confidence,
    this.recommendedDueDate,
    this.tags = const <String>[],
  });

  final String title;
  final String description;
  final double confidence;
  final DateTime? recommendedDueDate;
  final List<String> tags;

  TaskSuggestion copyWith({
    String? title,
    String? description,
    double? confidence,
    DateTime? recommendedDueDate,
    List<String>? tags,
  }) {
    return TaskSuggestion(
      title: title ?? this.title,
      description: description ?? this.description,
      confidence: confidence ?? this.confidence,
      recommendedDueDate: recommendedDueDate ?? this.recommendedDueDate,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        title,
        description,
        confidence,
        recommendedDueDate,
        tags,
      ];
}
