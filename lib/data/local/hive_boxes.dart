import 'package:hive_flutter/hive_flutter.dart';
import 'models/reminder_model.dart';
import 'models/screen_schedule_model.dart';
import 'models/mission_model.dart';
import 'models/user_stats_model.dart';

class HiveBoxes {
  static const String remindersBox = 'reminders';
  static const String schedulesBox = 'schedules';
  static const String settingsBox = 'settings';
  static const String analyticsBox = 'analytics';
  static const String missionsBox = 'missions';
  static const String userStatsBox = 'user_stats';

  static Future<void> registerAdapters() async {
    Hive.registerAdapter(ReminderModelAdapter());
    Hive.registerAdapter(ScreenScheduleModelAdapter());
    Hive.registerAdapter(MissionModelAdapter());
    Hive.registerAdapter(UserStatsModelAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<ReminderModel>(remindersBox);
    await Hive.openBox<ScreenScheduleModel>(schedulesBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(analyticsBox);
    await Hive.openBox<MissionModel>(missionsBox);
    await Hive.openBox<UserStatsModel>(userStatsBox);
  }

  static Box<ReminderModel> get reminders => Hive.box<ReminderModel>(remindersBox);
  static Box<ScreenScheduleModel> get schedules => Hive.box<ScreenScheduleModel>(schedulesBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get analytics => Hive.box(analyticsBox);
  static Box<MissionModel> get missions => Hive.box<MissionModel>(missionsBox);
  static Box<UserStatsModel> get userStats => Hive.box<UserStatsModel>(userStatsBox);
}
