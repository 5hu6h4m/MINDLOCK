import 'package:flutter_riverpod/flutter_riverpod.dart';

class InterestApps {
  static const Map<String, List<String>> mapping = {
    'Development': [
      'com.github.android',
      'com.stackexchange.stackoverflow',
      'com.microsoft.vscode',
      'com.jetbrains.intellij',
      'com.android.vending', // For app testing
      'io.github.muntashirakon.ocp', // Open source
      'com.termux',
      'com.google.android.apps.docs',
      'com.google.android.apps.codeedit',
    ],
    'Design': [
      'com.figma.mobile',
      'com.adobe.creativecloud',
      'com.canva.editor',
      'com.pinterest', // Can be both, but often for inspo
      'com.behance.behance',
    ],
    'Finance & Business': [
      'com.zerodha.kite3',
      'com.upstox.pro',
      'com.binance.dev',
      'com.linkedin.android',
      'com.microsoft.teams',
      'com.slack',
    ],
    'Health & Fitness': [
      'com.google.android.apps.fitness',
      'com.strava',
      'com.myfitnesspal.android',
    ],
    'Learning': [
      'com.udemy.android',
      'com.coursera.android',
      'org.edx.mobile',
      'com.duolingo',
      'com.khanacademy.android',
    ],
  };
}

final userInterestsProvider = StateNotifierProvider<UserInterestsNotifier, List<String>>((ref) {
  return UserInterestsNotifier();
});

class UserInterestsNotifier extends StateNotifier<List<String>> {
  UserInterestsNotifier() : super(['Development']); // Default interest

  void toggleInterest(String interest) {
    if (state.contains(interest)) {
      state = state.where((i) => i != interest).toList();
    } else {
      state = [...state, interest];
    }
  }

  void setInterests(List<String> interests) {
    state = interests;
  }
}
