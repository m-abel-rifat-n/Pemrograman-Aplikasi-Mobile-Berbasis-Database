import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../providers/task_provider.dart';
import 'tugas_baru_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  String _username = 'User';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final username = await AuthService().getUsername();
      if (!mounted) return;
      setState(() {
        _username = username[0].toUpperCase() + username.substring(1);
      });
    } catch (_) {}
  }

  void _goToTugasBaru(String category) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TugasBaruPage(initialCategory: category),
      ),
    );
    if (mounted) {
      context.read<TaskProvider>().loadTasks();
    }
  }

  // Compute weekly done-counts from the in-memory task list.
  List<int> _weeklyFrom(List<Task> tasks) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      final ds = _ds(day);
      return tasks.where((t) => t.dueDate == ds && t.isDone).length;
    });
  }

  // Compute consecutive-day streak from the in-memory task list.
  int _streakFrom(List<Task> tasks) {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final ds = _ds(now.subtract(Duration(days: i)));
      final count = tasks.where((t) => t.dueDate == ds && t.isDone).length;
      if (count > 0) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  String _ds(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // Watch provider — every task change (add/toggle/delete) auto-rebuilds this page.
    final tasks = context.watch<TaskProvider>().tasks;

    final done = tasks.where((t) => t.isDone).length;
    final undone = tasks.where((t) => !t.isDone).length;
    final weeklyCounts = _weeklyFrom(tasks);
    final streak = _streakFrom(tasks);

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id').format(now);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<TaskProvider>().loadTasks();
            await _loadUser();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(dateStr),
                const SizedBox(height: 18),
                _buildStatCards(done, undone),
                const SizedBox(height: 14),
                _buildWeeklyChart(weeklyCounts, streak),
                const SizedBox(height: 14),
                _buildCategoryCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, $_username',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateStr,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
        ),
      ],
    );
  }

  Widget _buildStatCards(int done, int undone) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'TUGAS SELESAI',
            count: done,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'BELUM SELESAI',
            count: undone,
            icon: Icons.radio_button_unchecked_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<int> weeklyCounts, int streak) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final todayIdx = DateTime.now().weekday - 1;
    final maxVal = weeklyCounts.isEmpty
        ? 1.0
        : weeklyCounts.reduce((a, b) => a > b ? a : b).toDouble();
    final chartMax = maxVal < 1 ? 5.0 : maxVal + 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tugas Selesai Minggu Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.4,
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '+$streak streak 🔥',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: i == todayIdx ? AppColors.primary : AppColors.inkMuted,
                              fontWeight: i == todayIdx ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = weeklyCounts.length > i ? weeklyCounts[i].toDouble() : 0.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val == 0 ? 0.3 : val,
                        color: i == todayIdx ? AppColors.primary : AppColors.primarySoft,
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return Row(
      children: [
        Expanded(
          child: _CategoryCard(
            color: AppColors.coral,
            softColor: AppColors.coralSoft,
            icon: Icons.star_rounded,
            label: 'Tugas Penting',
            hint: 'Prioritas tinggi',
            onAddTap: () => _goToTugasBaru('penting'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CategoryCard(
            color: AppColors.sage,
            softColor: AppColors.sageSoft,
            icon: Icons.check_circle_rounded,
            label: 'Tugas Biasa',
            hint: 'Aktivitas harian',
            onAddTap: () => _goToTugasBaru('biasa'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Color color;
  final Color softColor;
  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onAddTap;

  const _CategoryCard({
    required this.color,
    required this.softColor,
    required this.icon,
    required this.label,
    required this.hint,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
