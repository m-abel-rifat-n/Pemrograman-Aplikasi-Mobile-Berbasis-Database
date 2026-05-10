import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'tugas_baru_page.dart';

class TugasPage extends StatefulWidget {
  const TugasPage({super.key});

  @override
  State<TugasPage> createState() => _TugasPageState();
}

class _TugasPageState extends State<TugasPage> {
  String _filter = 'semua';

  List<Task> _filtered(List<Task> all) {
    if (_filter == 'penting') return all.where((t) => t.category == 'penting').toList();
    if (_filter == 'biasa') return all.where((t) => t.category == 'biasa').toList();
    return all;
  }

  Future<void> _editTask(Task task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TugasBaruPage(taskToEdit: task),
      ),
    );
    if (result == true && mounted) {
      context.read<TaskProvider>().loadTasks();
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, int id) async {
    final provider = context.read<TaskProvider>();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Tugas',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      provider.deleteTask(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final all = provider.tasks;
    final penting = all.where((t) => t.category == 'penting').length;
    final biasa = all.where((t) => t.category == 'biasa').length;
    final filtered = _filtered(all);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Semua Tugas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                _FilterChip(label: 'Semua', count: all.length, active: _filter == 'semua', onTap: () => setState(() => _filter = 'semua')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Penting', count: penting, active: _filter == 'penting', onTap: () => setState(() => _filter = 'penting')),
                const SizedBox(width: 6),
                _FilterChip(label: 'Biasa', count: biasa, active: _filter == 'biasa', onTap: () => setState(() => _filter = 'biasa')),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filtered.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _TaskRow(
                          task: filtered[i],
                          onToggle: (val) => context
                              .read<TaskProvider>()
                              .toggleDone(filtered[i].id!, val),
                          onEdit: () => _editTask(filtered[i]),
                          onDelete: () => _confirmDelete(context, filtered[i].id!),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: AppColors.inkMuted.withAlpha(120)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan tugas dari halaman Beranda',
            style: TextStyle(fontSize: 15, color: AppColors.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? AppColors.ink : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withAlpha(46)
                    : AppColors.bg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final void Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _accent => task.category == 'penting' ? AppColors.coral : AppColors.sage;

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd MMM', 'id').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: _accent.withAlpha(task.isDone ? 77 : 255),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => onToggle(!task.isDone),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: task.isDone ? _accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: task.isDone
                                ? null
                                : Border.all(color: AppColors.line, width: 1.6),
                          ),
                          child: task.isDone
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: task.isDone
                                    ? AppColors.inkMuted
                                    : AppColors.ink,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                letterSpacing: -0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 13, color: AppColors.inkSoft),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(task.dueDate),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppColors.line,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _accent.withAlpha(26),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    task.category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _accent,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onEdit,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: _accent,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
