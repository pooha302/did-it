import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Mapping of common codepoints to names for better GA readable reports
  static const Map<int, String> _iconNameMap = {
    0xe98a: 'coffee',
    0xebc1: 'glass_water',
    0xec80: 'utensils',
    0xe923: 'apple',
    0xea03: 'dumbbell',
    0xe949: 'bike',
    0xea43: 'footprints',
    0xea84: 'heart',
    0xe95d: 'book',
    0xeb1a: 'pencil',
    0xeaa4: 'laptop',
    0xe962: 'brain',
    0xeb26: 'pill',
    0xe940: 'bed',
    0xe93a: 'bath',
    0xea94: 'home',
    0xeb64: 'shopping_cart',
    0xec69: 'trash',
    0xead6: 'music',
    0xe986: 'camera',
    0xea58: 'gamepad',
    0xeb05: 'palette',
    0xeb7a: 'smile',
    0xe98d: 'clock',
  };

  // 1. Reset Action
  Future<void> logResetAction(String actionId, String actionName) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'action_reset',
        parameters: {
          'action_id': actionId,
          'action_name': actionName,
        },
      );
    } catch (_) {}
  }

  // 2 & 4. Add Action with full info
  Future<void> logAddAction({
    required String actionId,
    required String actionName,
    required int iconCodePoint,
    required String colorHex,
    required bool isPositiveGoal,
  }) async {
    try {
      final iconName = _iconNameMap[iconCodePoint] ?? 'unknown_$iconCodePoint';
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'action_add',
        parameters: {
          'action_id': actionId,
          'action_name': actionName,
          'icon': iconName,
          'color': colorHex,
          'goal_type': isPositiveGoal ? 'positive' : 'negative',
        },
      );
    } catch (_) {}
  }

  // 3 & 5. Delete Action with name
  Future<void> logDeleteAction(String actionId, String actionName) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'action_delete',
        parameters: {
          'action_id': actionId,
          'action_name': actionName,
        },
      );
    } catch (_) {}
  }

  // 6. Cloud Backup
  Future<void> logCloudBackup(String platform) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'cloud_backup',
        parameters: {
          'platform': platform,
        },
      );
    } catch (_) {}
  }

  // 7. Goal Type Change (Thumb up/down)
  Future<void> logGoalTypeChange(String actionId, bool isPositive) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'action_goal_type_change',
        parameters: {
          'action_id': actionId,
          'goal_type': isPositive ? 'positive' : 'negative',
        },
      );
    } catch (_) {}
  }

  // 8. Action Toggle (Active/Inactive)
  Future<void> logActionToggle(String actionId, bool isActive) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'action_toggle_status',
        parameters: {
          'action_id': actionId,
          'is_active': isActive ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  // 9. Reorder Actions
  Future<void> logReorderActions() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(name: 'action_reorder');
    } catch (_) {}
  }

  // 10. View Stats
  Future<void> logViewStats(String actionId) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'view_stats',
        parameters: {
          'action_id': actionId,
        },
      );
    } catch (_) {}
  }

  // 11. Cloud Restore
  Future<void> logCloudRestore(String platform) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'cloud_restore',
        parameters: {
          'platform': platform,
        },
      );
    } catch (_) {}
  }

  // 12. Language Change
  Future<void> logLanguageChange(String languageCode) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: 'language_change',
        parameters: {
          'language_code': languageCode,
        },
      );
    } catch (_) {}
  }

  // 13. Tutorial Complete
  Future<void> logTutorialComplete(String screenName) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logTutorialComplete();
      await _analytics.logEvent(
        name: 'tutorial_complete',
        parameters: {
          'screen_name': screenName,
        },
      );
    } catch (_) {}
  }
}
