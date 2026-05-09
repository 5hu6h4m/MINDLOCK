import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../data/repositories/reminder_repository.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? editData;
  const CreateReminderScreen({super.key, this.editData});

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  ReminderPriority _priority = ReminderPriority.medium;
  String _selectedTone = 'default';
  RepeatInterval _repeatInterval = RepeatInterval.fiveMin;
  int _repeatCount = 1;
  bool _isFullScreenMode = false;
  bool _isStrictMode = false;
  StrictModeType _strictType = StrictModeType.math;
  bool _isPersistent = false;
  int _vibrationIntensity = 1;
  bool _showAdvanced = false;
  bool _isSaving = false;

  late AnimationController _advancedController;
  late Animation<double> _advancedAnimation;

  @override
  void initState() {
    super.initState();
    _advancedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _advancedAnimation = CurvedAnimation(
      parent: _advancedController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _advancedController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryPurple,
            onPrimary: Colors.white,
            surface: AppTheme.bgDarkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryPurple,
            onPrimary: Colors.white,
            surface: AppTheme.bgDarkCard,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(reminderRepositoryProvider).createReminder(
            title: _titleController.text.trim(),
            description: _descController.text.trim(),
            dateTime: _selectedDate,
            priorityIndex: _priority.index,
            repeatIntervalMinutes: _repeatInterval == RepeatInterval.custom
                ? 5
                : _repeatInterval.minutes,
            repeatCount: _repeatCount,
            isFullScreenMode: _isFullScreenMode,
            isStrictMode: _isStrictMode,
            strictTypeIndex: _strictType.index,
            isPersistent: _isPersistent,
            vibrationIntensity: _vibrationIntensity,
            tone: _selectedTone,
          );

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder created ✅'),
            backgroundColor: AppTheme.accentGreen.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.accentRed),
        );
      }
    }
  }

  Widget _buildToneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Notification Tone'),
        DropdownButtonFormField<String>(
          value: _selectedTone,
          dropdownColor: AppTheme.bgDarkCard,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.music_note_rounded, color: AppTheme.primaryPurple),
          ),
          items: ['default', 'soft', 'alarm', 'urgent'].map((t) => DropdownMenuItem(
            value: t,
            child: Text(t.toUpperCase(), style: const TextStyle(color: AppTheme.textPrimary)),
          )).toList(),
          onChanged: (v) => setState(() => _selectedTone = v!),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Reminder'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryPurple))
                : const Text('Save',
                    style: TextStyle(
                        color: AppTheme.primaryPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
          ),
        ],
      ),
      body: Hero(
        tag: 'add_reminder',
        child: Material(
          color: Colors.transparent,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              physics: const BouncingScrollPhysics(),
              children: [
            // ── Title ─────────────────────────────────────────────────────
            _SectionLabel('Task Title'),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLength: 80,
              decoration: const InputDecoration(
                hintText: 'e.g. Call Ravi for payment',
                prefixIcon: Icon(Icons.title_rounded,
                    color: AppTheme.primaryPurple),
                counterStyle: TextStyle(color: AppTheme.textMuted),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────────────────
            _SectionLabel('Description (optional)'),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add details...',
                prefixIcon: Icon(Icons.notes_rounded,
                    color: AppTheme.primaryPurple),
              ),
            ),
            const SizedBox(height: 16),

            // ── Date & Time ───────────────────────────────────────────────
            _SectionLabel('Date & Time'),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppTheme.primaryPurple, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM yyyy')
                              .format(_selectedDate),
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(_selectedDate),
                          style: const TextStyle(
                              color: AppTheme.primaryPurple,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Priority ──────────────────────────────────────────────────
            _SectionLabel('Priority'),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 20),

            // ── Advanced ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                setState(() => _showAdvanced = !_showAdvanced);
                _showAdvanced
                    ? _advancedController.forward()
                    : _advancedController.reverse();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded,
                        color: AppTheme.primaryPurple),
                    const SizedBox(width: 12),
                    const Text('Advanced Settings',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _showAdvanced ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            SizeTransition(
              sizeFactor: _advancedAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildToneSelector(),
                  const SizedBox(height: 12),
                  _AdvancedPanel(
                    repeatInterval: _repeatInterval,
                    repeatCount: _repeatCount,
                    isFullScreenMode: _isFullScreenMode,
                    isStrictMode: _isStrictMode,
                    strictType: _strictType,
                    isPersistent: _isPersistent,
                    vibrationIntensity: _vibrationIntensity,
                    onRepeatIntervalChanged: (v) =>
                        setState(() => _repeatInterval = v),
                    onRepeatCountChanged: (v) =>
                        setState(() => _repeatCount = v),
                    onFullScreenChanged: (v) =>
                        setState(() => _isFullScreenMode = v),
                    onStrictModeChanged: (v) =>
                        setState(() => _isStrictMode = v),
                    onStrictTypeChanged: (v) =>
                        setState(() => _strictType = v),
                    onPersistentChanged: (v) =>
                        setState(() => _isPersistent = v),
                    onVibrationChanged: (v) =>
                        setState(() => _vibrationIntensity = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}
}

// ──────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.4)),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _PrioritySelector extends StatelessWidget {
  final ReminderPriority selected;
  final ValueChanged<ReminderPriority> onChanged;

  const _PrioritySelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ReminderPriority.values.map((p) {
        final color = Color(p.colorValue);
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.18) : AppTheme.bgDarkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppTheme.borderColor,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    p == ReminderPriority.emergency
                        ? Icons.warning_rounded
                        : p == ReminderPriority.high
                            ? Icons.priority_high_rounded
                            : p == ReminderPriority.medium
                                ? Icons.remove_rounded
                                : Icons.arrow_downward_rounded,
                    color: isSelected ? color : AppTheme.textMuted,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.label,
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _AdvancedPanel extends StatelessWidget {
  final RepeatInterval repeatInterval;
  final int repeatCount;
  final bool isFullScreenMode, isStrictMode, isPersistent;
  final StrictModeType strictType;
  final int vibrationIntensity;
  final ValueChanged<RepeatInterval> onRepeatIntervalChanged;
  final ValueChanged<int> onRepeatCountChanged;
  final ValueChanged<bool> onFullScreenChanged;
  final ValueChanged<bool> onStrictModeChanged;
  final ValueChanged<StrictModeType> onStrictTypeChanged;
  final ValueChanged<bool> onPersistentChanged;
  final ValueChanged<int> onVibrationChanged;

  const _AdvancedPanel({
    required this.repeatInterval,
    required this.repeatCount,
    required this.isFullScreenMode,
    required this.isStrictMode,
    required this.strictType,
    required this.isPersistent,
    required this.vibrationIntensity,
    required this.onRepeatIntervalChanged,
    required this.onRepeatCountChanged,
    required this.onFullScreenChanged,
    required this.onStrictModeChanged,
    required this.onStrictTypeChanged,
    required this.onPersistentChanged,
    required this.onVibrationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repeat Interval
          const Text('Repeat Interval',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RepeatInterval.values
                .where((r) => r != RepeatInterval.custom)
                .map((r) {
              final sel = r == repeatInterval;
              return GestureDetector(
                onTap: () => onRepeatIntervalChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primaryPurple.withOpacity(0.2)
                        : AppTheme.bgDarkElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? AppTheme.primaryPurple
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: Text(r.label,
                      style: TextStyle(
                          color: sel
                              ? AppTheme.primaryPurple
                              : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          // Repeat Count
          Row(
            children: [
              const Expanded(
                child: Text('Repeat Count',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgDarkElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded,
                          size: 16, color: AppTheme.textMuted),
                      onPressed: repeatCount > 1
                          ? () => onRepeatCountChanged(repeatCount - 1)
                          : null,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),
                    Text(
                      '$repeatCount',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded,
                          size: 16, color: AppTheme.primaryPurple),
                      onPressed: repeatCount < 20
                          ? () => onRepeatCountChanged(repeatCount + 1)
                          : null,
                      constraints: const BoxConstraints(
                          minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: AppTheme.borderColor, height: 24),

          // Toggles
          _ToggleRow(
            icon: Icons.fullscreen_rounded,
            label: 'Full-Screen Mode',
            subtitle: 'Overlay appears over lock screen',
            value: isFullScreenMode,
            onChanged: onFullScreenChanged,
            color: AppTheme.accentCyan,
          ),
          _ToggleRow(
            icon: Icons.lock_rounded,
            label: 'Strict Mode',
            subtitle: 'Math puzzle required to dismiss',
            value: isStrictMode,
            onChanged: onStrictModeChanged,
            color: AppTheme.accentAmber,
          ),
          _ToggleRow(
            icon: Icons.push_pin_rounded,
            label: 'Persistent',
            subtitle: 'Cannot be swiped away from notifications',
            value: isPersistent,
            onChanged: onPersistentChanged,
            color: AppTheme.accentRed,
          ),

          const Divider(color: AppTheme.borderColor, height: 24),

          // Vibration Intensity
          Row(
            children: [
              const Icon(Icons.vibration_rounded,
                  color: AppTheme.textSecondary, size: 16),
              const SizedBox(width: 8),
              const Text('Vibration',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
              ...List.generate(4, (i) {
                final sel = i == vibrationIntensity;
                return GestureDetector(
                  onTap: () => onVibrationChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryPurple
                          : AppTheme.bgDarkElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: sel
                              ? AppTheme.primaryPurple
                              : AppTheme.borderColor),
                    ),
                    child: Center(
                      child: Text(
                        ['0', '1', '2', '3'][i],
                        style: TextStyle(
                          color: sel ? Colors.white : AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryPurple,
          ),
        ],
      ),
    );
  }
}
