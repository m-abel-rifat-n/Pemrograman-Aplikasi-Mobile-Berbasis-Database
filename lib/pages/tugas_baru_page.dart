import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models/task.dart';
import '../services/database_helper.dart';

class TugasBaruPage extends StatefulWidget {
  final String? initialCategory;
  final Task? taskToEdit;

  const TugasBaruPage({super.key, this.initialCategory, this.taskToEdit});

  @override
  State<TugasBaruPage> createState() => _TugasBaruPageState();
}

class _TugasBaruPageState extends State<TugasBaruPage> {
  late String _category;
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _category = task?.category ?? widget.initialCategory ?? 'penting';
    _titleCtrl = TextEditingController(text: task?.title ?? '');
    _descCtrl = TextEditingController(text: task?.description ?? '');
    if (task?.dueDate != null) {
      _dueDate = DateTime.tryParse(task!.dueDate!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Color get _accent => _category == 'penting' ? AppColors.coral : AppColors.sage;
  Color get _accentSoft => _category == 'penting' ? AppColors.coralSoft : AppColors.sageSoft;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
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
                style: TextStyle(
                    color: AppColors.coral, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await DatabaseHelper.instance.deleteTask(widget.taskToEdit!.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas wajib diisi.')),
      );
      return;
    }
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jatuh tempo wajib diisi.')),
      );
      return;
    }
    setState(() => _saving = true);
    final db = DatabaseHelper.instance;
    final task = Task(
      id: widget.taskToEdit?.id,
      title: title,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dueDate: DateFormat('yyyy-MM-dd').format(_dueDate!),
      reminder: null,
      category: _category,
      isDone: widget.taskToEdit?.isDone ?? false,
      completedAt: widget.taskToEdit?.completedAt,
    );
    try {
      if (widget.taskToEdit != null) {
        await db.updateTask(task);
      } else {
        await db.insertTask(task);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('TugasBaruPage._save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tugas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.taskToEdit != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 22),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? 'Edit Tugas' : 'Tugas Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryToggle(),
            const SizedBox(height: 18),
            _buildFormCard(),
            const SizedBox(height: 14),
            _buildDescCard(),
            const SizedBox(height: 20),
            _buildSaveButton(),
            if (isEdit) ...[
              const SizedBox(height: 12),
              _buildDeleteButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryToggle() {
    return Row(
      children: [
        _Pill(
          label: 'Penting',
          active: _category == 'penting',
          color: AppColors.coral,
          onTap: () => setState(() => _category = 'penting'),
        ),
        const SizedBox(width: 8),
        _Pill(
          label: 'Biasa',
          active: _category == 'biasa',
          color: AppColors.sage,
          onTap: () => setState(() => _category = 'biasa'),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    final dateText = _dueDate != null
        ? DateFormat('dd MMM yyyy', 'id').format(_dueDate!)
        : 'Pilih tanggal';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'JUDUL TUGAS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 21,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
            decoration: InputDecoration(
              hintText: _category == 'penting'
                  ? 'Contoh: Submit laporan akhir'
                  : 'Contoh: Beli buah di pasar',
              hintStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 21,
                color: AppColors.inkMuted,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const Divider(color: AppColors.line, height: 28),
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.calendar_today_rounded, color: _accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JATUH TEMPO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _dueDate != null ? AppColors.ink : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.inkMuted, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESKRIPSI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.55),
            decoration: const InputDecoration(
              hintText: 'Tambahkan catatan, tautan, atau detail pekerjaan di sini…',
              hintStyle:
                  TextStyle(fontSize: 15, color: AppColors.inkMuted, height: 1.55),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'SIMPAN TUGAS',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _delete,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coral,
          side: const BorderSide(color: AppColors.coral),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'HAPUS TUGAS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? color : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.inkSoft,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
