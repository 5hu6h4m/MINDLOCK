import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../data/local/models/reminder_model.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});
  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Today', 'Upcoming', 'Completed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(reminderRepositoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text('Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primaryPurple),
            onPressed: () => context.push('/reminders/create'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            decoration: BoxDecoration(
              color: AppTheme.bgDarkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primaryPurple.withOpacity(0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppTheme.primaryPurple,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReminderList(
            reminders: repo.getToday(),
            emptyMessage: 'No reminders today',
            onRefresh: () => setState(() {}),
          ),
          _ReminderList(
            reminders: repo.getPending(),
            emptyMessage: 'No upcoming reminders',
            onRefresh: () => setState(() {}),
          ),
          _ReminderList(
            reminders: repo.getCompleted(),
            emptyMessage: 'Nothing completed yet',
            onRefresh: () => setState(() {}),
            isCompleted: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reminders/create'),
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Reminder',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ReminderList extends ConsumerWidget {
  final List<ReminderModel> reminders;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final bool isCompleted;

  const _ReminderList({
    required this.reminders,
    required this.emptyMessage,
    required this.onRefresh,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.celebration_rounded : Icons.notifications_off_rounded,
              size: 52,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryPurple,
      backgroundColor: AppTheme.bgDarkCard,
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        physics: const BouncingScrollPhysics(),
        itemCount: reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final r = reminders[i];
          return Dismissible(
            key: Key(r.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
              ),
              child: const Icon(Icons.delete_rounded,
                  color: AppTheme.accentRed),
            ),
            onDismissed: (_) async {
              await ref.read(reminderRepositoryProvider).deleteReminder(r.id);
              onRefresh();
            },
            child: _FullReminderCard(
              reminder: r,
              isCompleted: isCompleted,
              onDone: () async {
                await ref
                    .read(reminderRepositoryProvider)
                    .markCompleted(r.id);
                onRefresh();
              },
              onEdit: () => context.push('/reminders/create', extra: {
                'id': r.id,
                'title': r.title,
                'description': r.description,
              }),
            ),
          );
        },
      ),
    );
  }
}

class _FullReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final bool isCompleted;
  final VoidCallback onDone;
  final VoidCallback onEdit;

  const _FullReminderCard({
    required this.reminder,
    required this.isCompleted,
    required this.onDone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = Color(reminder.priority.colorValue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? AppTheme.accentGreen.withOpacity(0.2)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: priorityColor.withOpacity(0.3)),
                ),
                child: Text(
                  reminder.priority.label.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentGreen, size: 18)
              else
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_rounded,
                      color: AppTheme.textMuted, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reminder.title,
            style: TextStyle(
              color: isCompleted
                  ? AppTheme.textMuted
                  : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          if (reminder.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reminder.description,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: DateFormat('hh:mm a, d MMM').format(reminder.dateTime),
              ),
              if (reminder.repeatCount > 1) ...[
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.repeat_rounded,
                  label: '×${reminder.repeatCount} every ${reminder.repeatIntervalMinutes}m',
                  color: AppTheme.primaryPurple,
                ),
              ],
              const Spacer(),
              if (!isCompleted)
                GestureDetector(
                  onTap: onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.accentGreen.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}
