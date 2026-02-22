import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:synergy/models/user_task.dart';

/// Service untuk mengelola User Tasks (Aktivitas/Tugas)
/// Menyediakan CRUD operations untuk task management
class UserTaskService {
  final _supabase = Supabase.instance.client;

  /// Get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Get all tasks untuk user saat ini
  Future<List<UserTask>> getAllTasks() async {
    try {
      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', _currentUserId!)
          .order('due_date', ascending: true)
          .order('is_completed', ascending: true);

      return (response as List)
          .map((json) => UserTask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      rethrow;
    }
  }

  /// Get tasks untuk tanggal tertentu
  Future<List<UserTask>> getTasksForDate(DateTime date) async {
    try {
      final dateString = date.toIso8601String().split('T')[0]; // YYYY-MM-DD

      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('due_date', dateString)
          .order('is_completed', ascending: true)
          .order('priority', ascending: false)
          .order('due_time', ascending: true);

      return (response as List)
          .map((json) => UserTask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tasks for date: $e');
      rethrow;
    }
  }

  /// Get tasks untuk bulan tertentu (untuk calendar view)
  /// Returns Map<DateTime, List<UserTask>> - grouped by date
  Future<Map<DateTime, List<UserTask>>> getTasksForMonth(
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', _currentUserId!)
          .gte('due_date', startDate.toIso8601String().split('T')[0])
          .lte('due_date', endDate.toIso8601String().split('T')[0])
          .order('due_date', ascending: true);

      final tasks = (response as List)
          .map((json) => UserTask.fromJson(json as Map<String, dynamic>))
          .toList();

      // Group by date
      final Map<DateTime, List<UserTask>> tasksByDate = {};
      
      for (final task in tasks) {
        final date = DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
        );

        if (tasksByDate[date] == null) {
          tasksByDate[date] = [];
        }
        tasksByDate[date]!.add(task);
      }

      return tasksByDate;
    } catch (e) {
      print('Error getting tasks for month: $e');
      rethrow;
    }
  }

  /// Get pending (incomplete) tasks
  Future<List<UserTask>> getPendingTasks() async {
    try {
      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('is_completed', false)
          .order('due_date', ascending: true)
          .order('priority', ascending: false);

      return (response as List)
          .map((json) => UserTask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting pending tasks: $e');
      rethrow;
    }
  }

  /// Get completed tasks
  Future<List<UserTask>> getCompletedTasks() async {
    try {
      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('is_completed', true)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => UserTask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting completed tasks: $e');
      rethrow;
    }
  }

  /// Get overdue tasks (past due date, not completed)
  Future<List<UserTask>> getOverdueTasks() async {
    try {
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('user_tasks')
          .select()
          .eq('user_id', _currentUserId!)
          .eq('is_completed', false)
          .lt('due_date', todayString)
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => UserTask.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting overdue tasks: $e');
      rethrow;
    }
  }

  /// Create new task
  Future<UserTask> createTask(UserTask task) async {
    try {
      final taskData = task.toJson();
      
      // Remove id, created_at, updated_at (akan di-auto generate oleh DB)
      taskData.remove('id');
      taskData.remove('created_at');
      taskData.remove('updated_at');

      // Set user_id dari current user
      taskData['user_id'] = _currentUserId;

      final response = await _supabase
          .from('user_tasks')
          .insert(taskData)
          .select()
          .single();

      return UserTask.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  /// Update existing task
  Future<UserTask> updateTask(UserTask task) async {
    try {
      final taskData = task.toJson();
      
      // Remove fields yang tidak boleh di-update manual
      taskData.remove('id');
      taskData.remove('user_id');
      taskData.remove('created_at');
      taskData.remove('updated_at'); // Will be auto-updated by trigger

      final response = await _supabase
          .from('user_tasks')
          .update(taskData)
          .eq('id', task.id)
          .eq('user_id', _currentUserId!) // Security check
          .select()
          .single();

      return UserTask.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  /// Toggle task completion status
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _supabase
          .from('user_tasks')
          .update({'is_completed': isCompleted})
          .eq('id', taskId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      print('Error toggling task completion: $e');
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase
          .from('user_tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', _currentUserId!);
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  /// Get tasks count (for statistics)
  Future<Map<String, int>> getTasksCount() async {
    try {
      final allTasks = await getAllTasks();
      
      final pendingCount = allTasks.where((t) => !t.isCompleted).length;
      final completedCount = allTasks.where((t) => t.isCompleted).length;
      
      final today = DateTime.now();
      final overdueCount = allTasks.where((t) => 
        !t.isCompleted && 
        t.dueDate.isBefore(DateTime(today.year, today.month, today.day))
      ).length;

      return {
        'total': allTasks.length,
        'pending': pendingCount,
        'completed': completedCount,
        'overdue': overdueCount,
      };
    } catch (e) {
      print('Error getting tasks count: $e');
      return {
        'total': 0,
        'pending': 0,
        'completed': 0,
        'overdue': 0,
      };
    }
  }

  /// Get tasks grouped by priority
  Future<Map<TaskPriority, List<UserTask>>> getTasksByPriority() async {
    try {
      final tasks = await getPendingTasks();
      
      final Map<TaskPriority, List<UserTask>> grouped = {
        TaskPriority.high: [],
        TaskPriority.medium: [],
        TaskPriority.low: [],
      };

      for (final task in tasks) {
        grouped[task.priority]!.add(task);
      }

      return grouped;
    } catch (e) {
      print('Error getting tasks by priority: $e');
      rethrow;
    }
  }
}
