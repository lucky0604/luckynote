import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/services/task_action_service.dart';
import '../../../../database/database.dart';
import '../../../shared_infra/providers/database_provider.dart';

/// 任务筛选类型
enum TaskFilter { all, pending, completed }

/// 任务状态
class TasksState {
  const TasksState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filter = TaskFilter.pending,
  });

  final List<TaskWithDocument> tasks;
  final bool isLoading;
  final String? error;
  final TaskFilter filter;

  TasksState copyWith({
    List<TaskWithDocument>? tasks,
    bool? isLoading,
    String? error,
    TaskFilter? filter,
  }) {
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get totalCount => tasks.length;
}

/// 任务状态管理器
class TasksNotifier extends StateNotifier<TasksState> {
  TasksNotifier(this._ref) : super(const TasksState(isLoading: true)) {
    _subscribeToTasks();
  }

  final Ref _ref;
  StreamSubscription<List<TaskWithDocument>>? _subscription;

  TaskRepository get _taskRepo => _ref.read(taskRepositoryProvider);
  TaskActionService get _actionService => _ref.read(taskActionServiceProvider);
  AppDatabase get _db => _ref.read(databaseProvider);

  /// 订阅任务流，实现实时更新
  void _subscribeToTasks() {
    _subscription?.cancel();

    final filterValue = _getFilterValue(state.filter);
    _subscription = _taskRepo.watchAllTasks(filter: filterValue).listen(
      (tasks) {
        state = state.copyWith(tasks: tasks, isLoading: false, error: null);
      },
      onError: (e) {
        state = state.copyWith(isLoading: false, error: '加载失败: $e');
      },
    );
  }

  /// 根据筛选类型返回数据库查询参数
  bool? _getFilterValue(TaskFilter filter) {
    return switch (filter) {
      TaskFilter.all => null,
      TaskFilter.pending => false,
      TaskFilter.completed => true,
    };
  }

  /// 切换筛选类型
  void setFilter(TaskFilter filter) {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter, isLoading: true);
    _subscribeToTasks();
  }

  /// 手动刷新任务列表
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final filterValue = _getFilterValue(state.filter);
      final tasks = await _taskRepo.getAllTasks(filter: filterValue);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '刷新失败: $e');
    }
  }

  /// 切换任务状态
  Future<bool> toggleTask(int taskId) async {
    final success = await _actionService.toggleTaskStatus(taskId, _db);
    if (success) {
      // 强制刷新侧边栏任务列表，确保 UI 立即响应
      _ref.invalidate(sidebarTasksProvider);
    }
    return success;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

// ==================== Providers ====================

/// Task Repository Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskRepository(db);
});

/// Task Action Service Provider
final taskActionServiceProvider = Provider<TaskActionService>((ref) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  return TaskActionService(taskRepository: taskRepo);
});

/// 任务状态 Provider
final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final notifier = TasksNotifier(ref);
  ref.onDispose(() {
    notifier.dispose();
  });
  return notifier;
});

/// 未完成任务数量 provider
final tasksCountProvider = Provider<int>((ref) {
  final state = ref.watch(tasksProvider);
  // 如果当前筛选是 pending，直接用 tasks.length，否则计算 pendingCount
  if (state.filter == TaskFilter.pending) {
    return state.tasks.length;
  }
  return state.pendingCount;
});

/// 侧边栏任务概览 provider（仅未完成任务，限制数量）
final sidebarTasksProvider = StreamProvider<List<TaskWithDocument>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchPendingTasks().map((tasks) => tasks.take(10).toList());
});
