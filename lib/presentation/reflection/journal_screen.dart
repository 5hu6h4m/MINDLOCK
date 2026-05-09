import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/reflection_repository.dart';
import '../../data/local/models/daily_reflection_model.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final reflections = ref.watch(reflectionRepositoryProvider).getAll();
    
    final filteredReflections = reflections.where((r) {
      final dateStr = DateFormat('EEEE, MMM d, yyyy').format(r.date).toLowerCase();
      final summaryLower = r.summary.toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return summaryLower.contains(queryLower) || dateStr.contains(queryLower);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.bgDark,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
              title: const Text('MIND JOURNAL', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 18)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPurple.withOpacity(0.3), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search summaries or dates...',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryPurple, size: 20),
                    fillColor: Colors.white.withOpacity(0.05),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
          ),

          if (filteredReflections.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchQuery.isEmpty ? Icons.history_edu_rounded : Icons.search_off_rounded, 
                      color: AppTheme.textMuted, 
                      size: 64
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty ? 'No reflections yet.' : 'No results found.', 
                      style: const TextStyle(color: AppTheme.textMuted)
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ReflectionCard(reflection: filteredReflections[index]),
                  childCount: filteredReflections.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final DailyReflectionModel reflection;

  const _ReflectionCard({required this.reflection});

  @override
  Widget build(BuildContext context) {
    final moodEmojis = ['😫', '😕', '😐', '🙂', '🤩'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(reflection.date),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    reflection.isSynced ? 'Cloud Synced ☁️' : 'Local Only',
                    style: TextStyle(color: reflection.isSynced ? AppTheme.accentCyan : AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
              Text(moodEmojis[reflection.moodIndex], style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            reflection.summary,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
          const Divider(color: AppTheme.borderColor, height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reflection.aiVerdict,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
