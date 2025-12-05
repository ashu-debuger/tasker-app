import 'dart:math';

import '../models/task_suggestion.dart';
import '../models/task_suggestion_request.dart';
import 'task_suggestion_repository.dart';

/// Lightweight, offline implementation that fabricates suggestions using
/// project context instead of calling an external LLM. This keeps the feature
/// usable until a network-backed model is wired up.
class HeuristicTaskSuggestionRepository implements TaskSuggestionRepository {
  const HeuristicTaskSuggestionRepository();

  @override
  Future<List<TaskSuggestion>> generateSuggestions(
    TaskSuggestionRequest request,
  ) async {
    // Emit a short delay to mimic network latency and keep the UI consistent
    // with future remote providers.
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final engine = _HeuristicSuggestionEngine(request);
    return engine.build();
  }
}

class _HeuristicSuggestionEngine {
  _HeuristicSuggestionEngine(this.request);

  final TaskSuggestionRequest request;
  final List<TaskSuggestion> _suggestions = <TaskSuggestion>[];
  final Set<String> _titles = <String>{};
  final Random _random = Random();

  List<TaskSuggestion> build() {
    _seedFromKeywords();
    _seedFromRecentTasks();
    _seedTemporalIdeas();
    _fillWithGeneralIdeas();

    if (_suggestions.isEmpty) {
      _addSuggestion(
        title: 'Plan ${request.projectName} sprint goals',
        description:
            'Outline the next 3 milestones for ${request.projectName} and share them with the team.',
        confidence: 0.55,
        tags: const <String>['planning'],
      );
    }

    final desired = request.desiredCount;
    return _suggestions.take(desired).toList(growable: false);
  }

  void _seedFromKeywords() {
    if (request.keywords.isEmpty) return;

    final prioritized = request.keywords.take(5);
    for (final keyword in prioritized) {
      final normalized = _titleCase(keyword.trim());
      if (normalized.isEmpty) continue;
      _addSuggestion(
        title: 'Deep dive: $normalized roadmap',
        description:
            'Review open items related to "$normalized" and define the next actionable task.',
        confidence: 0.72 - _decayByIndex(prioritized, keyword),
        tags: <String>['focus', normalized.toLowerCase()],
      );
    }
  }

  void _seedFromRecentTasks() {
    if (request.recentTasks.isEmpty) return;

    final backlogGap = request.recentTasks.length >= request.desiredCount;
    if (backlogGap) {
      _addSuggestion(
        title: 'Retro: unblock lingering tasks',
        description:
            'Inspect the oldest tasks in ${request.projectName} and convert blockers into concrete follow-ups.',
        confidence: 0.68,
        tags: const <String>['retro'],
      );
    }

    final carryOvers = request.recentTasks.take(3);
    for (final task in carryOvers) {
      final keyword = _extractPrimaryKeyword(task);
      if (keyword == null) continue;
      _addSuggestion(
        title: 'Finalize ${_titleCase(keyword)} deliverable',
        description:
            'Close the loop on "$task" by preparing a definition-of-done checklist.',
        confidence: 0.64,
        tags: <String>['follow-up'],
      );
    }
  }

  void _seedTemporalIdeas() {
    final dueDate = request.desiredDueDate;
    if (dueDate == null) return;

    final daysLeft = dueDate.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) {
      _addSuggestion(
        title: 'Post-mortem for ${request.projectName}',
        description:
            'Capture learnings from the latest milestone to improve the next iteration.',
        confidence: 0.58,
        tags: const <String>['learning'],
      );
      return;
    }

    final urgencyTag = daysLeft <= 3 ? 'urgent' : 'planning';
    _addSuggestion(
      title: 'Prepare milestone handoff (${daysLeft.toString()}d left)',
      description:
          'Align owners on deliverables due in $daysLeft days and confirm dependencies.',
      confidence: daysLeft <= 3 ? 0.81 : 0.7,
      tags: <String>[urgencyTag],
      recommendedDueDate: dueDate.subtract(const Duration(days: 1)),
    );
  }

  void _fillWithGeneralIdeas() {
    const backlog = <Map<String, Object>>[
      {
        'title': 'Document the success criteria',
        'description':
            'Write a short paragraph describing what success looks like for the next deliverable.',
        'tags': <String>['documentation'],
      },
      {
        'title': 'Create a risk radar',
        'description':
            'List the top 3 risks for the project and propose mitigations.',
        'tags': <String>['risk'],
      },
      {
        'title': 'Schedule teammate sync',
        'description':
            'Invite stakeholders to a 15-minute touchpoint to surface blockers early.',
        'tags': <String>['collaboration'],
      },
      {
        'title': 'Automate a repetitive step',
        'description':
            'Identify one manual task you can templatize or script this week.',
        'tags': <String>['automation'],
      },
    ];

    for (final template in backlog) {
      _addSuggestion(
        title: template['title']! as String,
        description: template['description']! as String,
        confidence: 0.45 + _random.nextDouble() * 0.2,
        tags: (template['tags']! as List<String>),
      );
    }
  }

  void _addSuggestion({
    required String title,
    required String description,
    required double confidence,
    DateTime? recommendedDueDate,
    List<String> tags = const <String>[],
  }) {
    if (_titles.contains(title)) return;
    _titles.add(title);
    _suggestions.add(
      TaskSuggestion(
        title: title,
        description: description,
        confidence: confidence.clamp(0.0, 1.0),
        recommendedDueDate: recommendedDueDate ?? _defaultDueDate(),
        tags: List<String>.from(tags),
      ),
    );
  }

  double _decayByIndex(Iterable iterable, Object current) {
    final index = iterable.toList().indexOf(current);
    if (index < 0) return 0;
    return min(0.25, index * 0.05);
  }

  String? _extractPrimaryKeyword(String taskTitle) {
    final tokens = taskTitle
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((token) => token.length > 3)
        .toList();
    return tokens.isEmpty ? null : tokens.first.toLowerCase();
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  DateTime _defaultDueDate() {
    return request.desiredDueDate ??
        DateTime.now().add(const Duration(days: 3));
  }
}
