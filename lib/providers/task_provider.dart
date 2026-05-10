import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/database_helper.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _loading = true; // true until first load completes

  List<Task> get tasks => _tasks;
  bool get loading => _loading;

  List<Task> get pendingTasks => _tasks.where((t) => t.category == 'penting').toList();
  List<Task> get biasaTasks => _tasks.where((t) => t.category == 'biasa').toList();

  Future<void> loadTasks() async {
    _loading = true;
    notifyListeners();
    try {
      _tasks = await DatabaseHelper.instance.getAllTasks();
    } catch (e) {
      debugPrint('TaskProvider.loadTasks error: $e');
      _tasks = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    await DatabaseHelper.instance.insertTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await DatabaseHelper.instance.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleDone(int id, bool isDone) async {
    await DatabaseHelper.instance.toggleDone(id, isDone);
    await loadTasks();
  }
}
