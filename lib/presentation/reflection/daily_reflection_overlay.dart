import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/platform_channel.dart';
import '../../services/ai_suggestion_service.dart';
import '../../data/repositories/reflection_repository.dart';
import '../../data/local/models/daily_reflection_model.dart';
import 'package:uuid/uuid.dart';

class DailyReflectionOverlay extends ConsumerStatefulWidget {
  const DailyReflectionOverlay({super.key});

  @override
  ConsumerState<DailyReflectionOverlay> createState() => _DailyReflectionOverlayState();
}

class _DailyReflectionOverlayState extends ConsumerState<DailyReflectionOverlay> {
  final TextEditingController _summaryController = TextEditingController();
  Map<String, int> _usageData = {};
  bool _isLoading = true;
  int _selectedMood = 2;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await PlatformChannel.getUsageStats(period: 'day');
    if (mounted) {
      setState(() {
        _usageData = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_summaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least a few words about your day. 🦾'))
      );
      return;
    }

    final aiService = ref.read(aiSuggestionServiceProvider);
    final verdict = aiService.analyzeDailyReflection(_summaryController.text, _usageData);

    final reflection = DailyReflectionModel(
      id: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      date: DateTime.now(),
      summary: _summaryController.text,
      appUsage: _usageData,
      aiVerdict: verdict,
      moodIndex: _selectedMood,
    );

    // 1. Save locally and trigger unlock IMMEDIATELY for speed
    ref.read(reflectionRepositoryProvider).saveReflection(reflection);
    PlatformChannel.stopReflectionService();
    
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withOpacity(0.12),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120), child: const SizedBox()),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'NIGHTLY REFLECTION',
                    style: TextStyle(color: AppTheme.primaryPurple, letterSpacing: 3, fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'How was your day?',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 24),
                  
                  // Usage Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.accentCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.bar_chart_rounded, color: AppTheme.accentCyan, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text('Digital Footprint', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildUsageList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Journal Input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('DAILY JOURNAL', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              Icon(Icons.edit_note_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _summaryController,
                              maxLines: null,
                              style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.6, fontWeight: FontWeight.w400),
                              decoration: const InputDecoration(
                                hintText: 'Aaj ka din kaisa raha? Share your thoughts...',
                                hintStyle: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Mood Selector
                  const Center(child: Text('RATE YOUR VIBE', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final moods = ['😫', '😕', '😐', '🙂', '🤩'];
                      final isSelected = _selectedMood == index;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMood = index),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: isSelected ? 1.3 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryPurple.withOpacity(0.2) : Colors.white.withOpacity(0.03),
                              shape: BoxShape.circle,
                              boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 15, spreadRadius: -2)] : null,
                            ),
                            child: Text(moods[index], style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 40),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            PlatformChannel.snoozeDailyReflection();
                            PlatformChannel.stopReflectionService();
                            context.go('/home');
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
                          ),
                          child: const Text('SNOOZE', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: const Text('SUBMIT LOG', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageList() {
    if (_usageData.isEmpty) return const Text('No usage recorded today.', style: TextStyle(color: AppTheme.textMuted));
    
    final sorted = _usageData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top3 = sorted.take(3).toList();

    return Column(
      children: top3.map((e) {
        final appName = e.key.split('.').last.toUpperCase();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appName, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              Text('${e.value} mins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
