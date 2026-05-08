import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/enums.dart';

class MissionCreationScreen extends StatefulWidget {
  const MissionCreationScreen({super.key});

  @override
  State<MissionCreationScreen> createState() => _MissionCreationScreenState();
}

class _MissionCreationScreenState extends State<MissionCreationScreen> {
  final _titleController = TextEditingController();
  MissionCategory _selectedCategory = MissionCategory.study;
  int _durationMinutes = 60;
  MissionIntensity _selectedIntensity = MissionIntensity.medium;

  final List<int> _durations = [15, 30, 45, 60, 90, 120, 180, 240];
  
  bool _isCoFocusEnabled = false;
  final _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _startMission() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a mission title'), backgroundColor: AppTheme.accentRed),
      );
      return;
    }

    // Navigate to Active Mission Screen
    context.push('/mission/active', extra: {
      'title': _titleController.text.trim(),
      'category': _selectedCategory.index,
      'duration': _durationMinutes,
      'intensity': _selectedIntensity.index,
      'isCoFocus': _isCoFocusEnabled,
      'roomCode': _roomCodeController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryPurple.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  title: const Text(
                    'NEW MISSION',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Input
                        TextField(
                          controller: _titleController,
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                          decoration: InputDecoration(
                            hintText: 'What is your mission?',
                            hintStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppTheme.textMuted.withOpacity(0.3),
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 40),

                        // Category
                        const Text('CATEGORY', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: MissionCategory.values.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryPurple.withOpacity(0.15) : AppTheme.bgDarkCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryPurple : AppTheme.borderColor,
                                  ),
                                ),
                                child: Text(
                                  cat.label,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),

                        // Duration
                        const Text('DURATION', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _durations.length,
                            itemBuilder: (ctx, i) {
                              final min = _durations[i];
                              final isSelected = _durationMinutes == min;
                              return GestureDetector(
                                onTap: () => setState(() => _durationMinutes = min),
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.accentBlue.withOpacity(0.15) : AppTheme.bgDarkCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.accentBlue : AppTheme.borderColor,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$min\nmin',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected ? AppTheme.accentBlue : AppTheme.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      fontSize: 14,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Intensity
                        const Text('INTENSITY', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        ...MissionIntensity.values.map((intensity) {
                          final isSelected = _selectedIntensity == intensity;
                          Color color = AppTheme.textPrimary;
                          if (intensity == MissionIntensity.medium) color = AppTheme.accentAmber;
                          if (intensity == MissionIntensity.hardcore) color = AppTheme.accentRed;

                          return GestureDetector(
                            onTap: () => setState(() => _selectedIntensity = intensity),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withOpacity(0.1) : AppTheme.bgDarkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? color.withOpacity(0.5) : AppTheme.borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    intensity == MissionIntensity.light ? Icons.notifications_none_rounded
                                      : intensity == MissionIntensity.medium ? Icons.block_rounded
                                      : Icons.warning_rounded,
                                    color: isSelected ? color : AppTheme.textMuted,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          intensity.label,
                                          style: TextStyle(
                                            color: isSelected ? color : AppTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          intensity == MissionIntensity.light ? 'Normal timer with reminders'
                                            : intensity == MissionIntensity.medium ? 'Blocks Instagram, YouTube, etc.'
                                            : 'Strict lockdown, tracks escape attempts',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: color),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 40),

                        // Co-Focus Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentCyan.withOpacity(0.1),
                                AppTheme.accentBlue.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people_alt_rounded, color: AppTheme.accentCyan),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Co-Focus Buddy',
                                          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          'Focus together with friends',
                                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isCoFocusEnabled,
                                    onChanged: (v) => setState(() => _isCoFocusEnabled = v),
                                    activeColor: AppTheme.accentCyan,
                                  ),
                                ],
                              ),
                              if (_isCoFocusEnabled) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _roomCodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Enter 4-digit Room Code',
                                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    counterText: '',
                                    filled: true,
                                    fillColor: AppTheme.bgDark.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.key_rounded, size: 18),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Shared punishment: If anyone leaves, everyone fails.',
                                  style: TextStyle(color: AppTheme.accentAmber, fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Start Button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: _startMission,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryPurple, AppTheme.accentBlue],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'INITIALIZE MISSION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
