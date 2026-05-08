import 'package:flutter/material.dart';

enum SuggestionAction {
  createReminder,
  startMission,
  openSleepTimer,
  viewAnalytics,
  none
}

class SuggestionModel {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final SuggestionAction action;
  final String actionLabel;

  SuggestionModel({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.action = SuggestionAction.none,
    this.actionLabel = '',
  });
}
