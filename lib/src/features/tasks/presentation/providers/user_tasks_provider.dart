import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/task.dart';
import '../../../../core/providers/providers.dart';

final userTasksProvider = StreamProvider.family<List<Task>, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) {
    return const Stream.empty();
  }
  final repository = ref.watch(taskRepositoryProvider);
  return repository.streamTasksForUser(userId);
});
