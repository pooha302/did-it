import '../main.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  FirebaseAnalytics? get _analytics => isFirebaseInitialized ? FirebaseAnalytics.instance : null;

  Future<void> _logEvent(String name, [Map<String, Object>? parameters]) async {
    try {
      final analytics = _analytics;
      if (analytics == null) return;
      await analytics.setAnalyticsCollectionEnabled(true);
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }

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
    0xea40: 'bed',
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

  Future<void> logResetAction(String actionId, String actionName) async {
    await _logEvent('action_reset', {
      'action_id': actionId,
      'action_name': actionName,
    });
  }

  Future<void> logAddAction({
    required String actionId,
    required String actionName,
    required int iconCodePoint,
    required String colorHex,
    required bool isPositiveGoal,
  }) async {
    final iconName = _iconNameMap[iconCodePoint] ?? 'unknown_$iconCodePoint';
    await _logEvent('action_add', {
      'action_id': actionId,
      'action_name': actionName,
      'icon': iconName,
      'color': colorHex,
      'goal_type': isPositiveGoal ? 'positive' : 'negative',
    });
  }

  Future<void> logDeleteAction(String actionId, String actionName) async {
    await _logEvent('action_delete', {
      'action_id': actionId,
      'action_name': actionName,
    });
  }

  Future<void> logCloudBackup(String platform) async {
    await _logEvent('cloud_backup', {'platform': platform});
  }

  Future<void> logGoalTypeChange(String actionId, bool isPositive) async {
    await _logEvent('action_goal_type_change', {
      'action_id': actionId,
      'goal_type': isPositive ? 'positive' : 'negative',
    });
  }

  Future<void> logActionToggle(String actionId, bool isActive) async {
    await _logEvent('action_toggle_status', {
      'action_id': actionId,
      'is_active': isActive ? 1 : 0,
    });
  }

  Future<void> logReorderActions() async {
    await _logEvent('action_reorder');
  }

  Future<void> logViewStats(String actionId) async {
    await _logEvent('view_stats', {'action_id': actionId});
  }

  Future<void> logCloudRestore(String platform) async {
    await _logEvent('cloud_restore', {'platform': platform});
  }

  Future<void> logLanguageChange(String languageCode) async {
    await _logEvent('language_change', {'language_code': languageCode});
  }

  Future<void> logTutorialComplete(String screenName) async {
    await _logEvent('tutorial_complete', {'screen_name': screenName});
  }
}
