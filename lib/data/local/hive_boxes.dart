import 'package:hive_flutter/hive_flutter.dart';
import 'models/reminder_model.dart';
import 'models/screen_schedule_model.dart';
import 'models/mission_model.dart';
import 'models/user_stats_model.dart';
import 'models/timetable_model.dart';
import 'models/co_focus_model.dart';
import 'models/daily_reflection_model.dart';

class HiveBoxes {
  static const String remindersBox = 'reminders';
  static const String schedulesBox = 'schedules';
  static const String settingsBox = 'settings';
  static const String analyticsBox = 'analytics';
  static const String missionsBox = 'missions';
  static const String userStatsBox = 'user_stats';
  static const String timetableBox = 'timetable';
  static const String coFocusBox = 'co_focus';
  static const String reflectionsBox = 'reflections';

  static Future<void> registerAdapters() async {
    Hive.registerAdapter(ReminderModelAdapter());
    Hive.registerAdapter(ScreenScheduleModelAdapter());
    Hive.registerAdapter(MissionModelAdapter());
    Hive.registerAdapter(UserStatsModelAdapter());
    Hive.registerAdapter(TimetableSlotAdapter());
    Hive.registerAdapter(CoFocusSessionAdapter());
    Hive.registerAdapter(DailyReflectionModelAdapter());
  }

  static Future<void> openBoxes() async {
    await Hive.openBox<ReminderModel>(remindersBox);
    await Hive.openBox<ScreenScheduleModel>(schedulesBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(analyticsBox);
    await Hive.openBox<MissionModel>(missionsBox);
    await Hive.openBox<UserStatsModel>(userStatsBox);
    await Hive.openBox<TimetableSlot>(timetableBox);
    await Hive.openBox<CoFocusSession>(coFocusBox);
    await Hive.openBox<DailyReflectionModel>(reflectionsBox);
  }

  static Box<ReminderModel> get reminders => Hive.box<ReminderModel>(remindersBox);
  static Box<ScreenScheduleModel> get schedules => Hive.box<ScreenScheduleModel>(schedulesBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get analytics => Hive.box(analyticsBox);
  static Box<MissionModel> get missions => Hive.box<MissionModel>(missionsBox);
  static Box<UserStatsModel> get userStats => Hive.box<UserStatsModel>(userStatsBox);
  static Box<TimetableSlot> get timetable => Hive.box<TimetableSlot>(timetableBox);
  static Box<CoFocusSession> get coFocus => Hive.box<CoFocusSession>(coFocusBox);
  static Box<DailyReflectionModel> get reflections => Hive.box<DailyReflectionModel>(reflectionsBox);
}
