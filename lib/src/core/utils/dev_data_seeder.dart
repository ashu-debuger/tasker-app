import 'package:flutter/foundation.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/projects/data/repositories/project_repository.dart';
import '../../features/tasks/data/repositories/task_repository.dart';
import '../../features/projects/domain/models/project.dart';
import '../../features/tasks/domain/models/task.dart';
import '../../features/tasks/domain/models/subtask.dart';

/// Development utility for seeding sample data
/// Only works in debug mode
class DevDataSeeder {
  final AuthRepository _authRepository;
  final ProjectRepository _projectRepository;
  final TaskRepository _taskRepository;

  DevDataSeeder({
    required AuthRepository authRepository,
    required ProjectRepository projectRepository,
    required TaskRepository taskRepository,
  }) : _authRepository = authRepository,
       _projectRepository = projectRepository,
       _taskRepository = taskRepository;

  /// Check if we can seed data (must be debug mode and user authenticated)
  Future<bool> canSeed() async {
    if (kReleaseMode) return false;

    final user = _authRepository.currentUser;
    return user != null;
  }

  /// Seed sample projects, tasks, and subtasks
  Future<void> seedSampleData() async {
    if (!await canSeed()) {
      throw Exception(
        'Cannot seed data: must be in debug mode and authenticated',
      );
    }

    final user = _authRepository.currentUser!;
    final userId = user.id;
    final now = DateTime.now();

    // Create sample projects
    final project1 = Project(
      id: 'dev_project_1',
      name: 'Mobile App Development',
      description: 'Building a task management app with Flutter and Firebase',
      members: [userId],
      createdAt: now.subtract(const Duration(days: 10)),
      ownerId: userId,
      memberRoles: {userId: 'owner'},
    );

    final project2 = Project(
      id: 'dev_project_2',
      name: 'Website Redesign',
      description: 'Redesigning company website with modern UI/UX',
      members: [userId],
      createdAt: now.subtract(const Duration(days: 5)),
      ownerId: userId,
      memberRoles: {userId: 'owner'},
    );

    final project3 = Project(
      id: 'dev_project_3',
      name: 'Personal Goals 2025',
      description: 'Track and achieve personal development goals',
      members: [userId],
      createdAt: now.subtract(const Duration(days: 2)),
      ownerId: userId,
      memberRoles: {userId: 'owner'},
    );

    // Save projects
    await _projectRepository.createProject(project1);
    await _projectRepository.createProject(project2);
    await _projectRepository.createProject(project3);

    // Create tasks for project 1
    final task1 = Task(
      id: 'dev_task_1_1',
      projectId: project1.id,
      title: 'Set up Firebase Authentication',
      description: 'Implement email/password and Google sign-in',
      status: TaskStatus.completed,
      dueDate: now.subtract(const Duration(days: 8)),
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 9)),
    );

    final task2 = Task(
      id: 'dev_task_1_2',
      projectId: project1.id,
      title: 'Design data models',
      description:
          'Create Project, Task, Subtask, and Chat models with serialization',
      status: TaskStatus.completed,
      dueDate: now.subtract(const Duration(days: 6)),
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 8)),
    );

    final task3 = Task(
      id: 'dev_task_1_3',
      projectId: project1.id,
      title: 'Build UI screens',
      description: 'Implement all main screens with Material 3 design',
      status: TaskStatus.inProgress,
      dueDate: now.add(const Duration(days: 3)),
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 5)),
    );

    final task4 = Task(
      id: 'dev_task_1_4',
      projectId: project1.id,
      title: 'Write unit tests',
      description:
          'Add comprehensive test coverage for repositories and notifiers',
      status: TaskStatus.pending,
      dueDate: now.add(const Duration(days: 7)),
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 3)),
    );

    // Create tasks for project 2
    final task5 = Task(
      id: 'dev_task_2_1',
      projectId: project2.id,
      title: 'Create wireframes',
      description: 'Design mockups for all pages',
      status: TaskStatus.completed,
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 4)),
    );

    final task6 = Task(
      id: 'dev_task_2_2',
      projectId: project2.id,
      title: 'Implement homepage',
      description: 'Build responsive homepage with hero section',
      status: TaskStatus.inProgress,
      dueDate: now.add(const Duration(days: 2)),
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final task7 = Task(
      id: 'dev_task_2_3',
      projectId: project2.id,
      title: 'Setup hosting',
      description: 'Deploy to production server',
      status: TaskStatus.pending,
      dueDate: now.add(const Duration(days: 10)),
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 1)),
    );

    // Create tasks for project 3
    final task8 = Task(
      id: 'dev_task_3_1',
      projectId: project3.id,
      title: 'Exercise 3 times per week',
      description: 'Maintain regular fitness routine',
      status: TaskStatus.inProgress,
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final task9 = Task(
      id: 'dev_task_3_2',
      projectId: project3.id,
      title: 'Read 12 books this year',
      description: 'Read at least one book per month',
      status: TaskStatus.inProgress,
      assignees: [userId],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    // Save all tasks
    await _taskRepository.createTask(task1);
    await _taskRepository.createTask(task2);
    await _taskRepository.createTask(task3);
    await _taskRepository.createTask(task4);
    await _taskRepository.createTask(task5);
    await _taskRepository.createTask(task6);
    await _taskRepository.createTask(task7);
    await _taskRepository.createTask(task8);
    await _taskRepository.createTask(task9);

    // Create subtasks for task 3 (Build UI screens)
    final subtasks3 = [
      Subtask(
        id: 'dev_subtask_3_1',
        taskId: task3.id,
        title: 'Projects list screen',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Subtask(
        id: 'dev_subtask_3_2',
        taskId: task3.id,
        title: 'Project detail screen',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Subtask(
        id: 'dev_subtask_3_3',
        taskId: task3.id,
        title: 'Task detail screen',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Subtask(
        id: 'dev_subtask_3_4',
        taskId: task3.id,
        title: 'Chat screen',
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Subtask(
        id: 'dev_subtask_3_5',
        taskId: task3.id,
        title: 'Settings screen',
        isCompleted: false,
        createdAt: now,
      ),
    ];

    // Create subtasks for task 4 (Write unit tests)
    final subtasks4 = [
      Subtask(
        id: 'dev_subtask_4_1',
        taskId: task4.id,
        title: 'Auth repository tests',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      Subtask(
        id: 'dev_subtask_4_2',
        taskId: task4.id,
        title: 'Project repository tests',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      Subtask(
        id: 'dev_subtask_4_3',
        taskId: task4.id,
        title: 'Task repository tests',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ];

    // Create subtasks for task 6 (Implement homepage)
    final subtasks6 = [
      Subtask(
        id: 'dev_subtask_6_1',
        taskId: task6.id,
        title: 'Hero section',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Subtask(
        id: 'dev_subtask_6_2',
        taskId: task6.id,
        title: 'Features section',
        isCompleted: true,
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      Subtask(
        id: 'dev_subtask_6_3',
        taskId: task6.id,
        title: 'Testimonials',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      Subtask(
        id: 'dev_subtask_6_4',
        taskId: task6.id,
        title: 'Contact form',
        isCompleted: false,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];

    // Create subtasks for task 8 (Exercise)
    final subtasks8 = [
      Subtask(
        id: 'dev_subtask_8_1',
        taskId: task8.id,
        title: 'Monday workout',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Subtask(
        id: 'dev_subtask_8_2',
        taskId: task8.id,
        title: 'Wednesday workout',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Subtask(
        id: 'dev_subtask_8_3',
        taskId: task8.id,
        title: 'Friday workout',
        isCompleted: false,
        createdAt: now,
      ),
    ];

    // Save all subtasks
    for (final subtask in [
      ...subtasks3,
      ...subtasks4,
      ...subtasks6,
      ...subtasks8,
    ]) {
      await _taskRepository.createSubtask(subtask);
    }
  }

  /// Clear all seeded data
  /// Use with caution - this deletes all projects, tasks, and subtasks for current user
  Future<void> clearSampleData() async {
    if (!await canSeed()) {
      throw Exception(
        'Cannot clear data: must be in debug mode and authenticated',
      );
    }

    // Delete all dev projects (this cascades to tasks and subtasks via Firestore rules)
    final devProjectIds = ['dev_project_1', 'dev_project_2', 'dev_project_3'];

    for (final projectId in devProjectIds) {
      try {
        await _projectRepository.deleteProject(projectId);
      } catch (e) {
        // Ignore errors if project doesn't exist
      }
    }
  }
}
