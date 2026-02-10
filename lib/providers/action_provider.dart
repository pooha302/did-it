import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/action.dart';
import '../services/cloud_backup_service.dart';
import '../services/analytics_service.dart';
import 'package:home_widget/home_widget.dart';
import 'locale_provider.dart';
import 'dart:ui' as ui;

class ActionProvider with ChangeNotifier {
  Map<String, ActionData> _actionStates = {
    for (var action in baseActions)
      action.id: ActionData(
        isActive: action.id == 'coffee' || action.id == 'water',
        isPositiveGoal: action.id != 'coffee' && action.id != 'snack',
        goal: action.id == 'coffee' ? 3 : (action.id == 'water' ? 8 : 0),
      )
  };
  List<String> _actionOrder = baseActions.map((h) => h.id).toList();
  List<ActionConfig> _customActions = [];

  int _activeActionIndex = 0;
  int _statsPeriod = 7;
  int _customStatsPeriod = 60; // Default custom period is 60 as requested
  bool _showGoalsInstruction = true;
  bool _showStats = false;
  List<String> _deletedPredefinedActionIds = [];

  Map<String, ActionData> get actionStates => _actionStates;
  int get activeActionIndex => _activeActionIndex;
  List<String> get actionOrder => _actionOrder;
  int get statsPeriod => _statsPeriod;
  int get customStatsPeriod => _customStatsPeriod;
  bool get showGoalsInstruction => _showGoalsInstruction;
  bool get showStats => _showStats;
  
  List<ActionConfig> get allActionsByOrder {
    final all = [...baseActions, ..._customActions];
    return _actionOrder
        .map((id) => all.firstWhere((h) => h.id == id, orElse: () => baseActions[0]))
        .toList();
  }

  List<ActionConfig> get activeActions => allActionsByOrder.where((h) => _actionStates[h.id]?.isActive ?? false).toList();
  
  ActionConfig get activeAction {
    final actions = activeActions;
    if (actions.isEmpty) return baseActions[0];
    final safeIndex = _activeActionIndex >= actions.length ? 0 : _activeActionIndex;
    return actions[safeIndex];
  }

  ActionConfig get statsAction => activeAction;

  ActionData get activeState {
    final actions = activeActions;
    if (actions.isEmpty) return ActionData();
    final safeIndex = _activeActionIndex >= actions.length ? 0 : _activeActionIndex;
    return _actionStates[actions[safeIndex].id] ?? ActionData();
  }

  ActionProvider() {
    _loadData();
  }

  void setActiveActionIndex(int index) {
    if (_activeActionIndex == index) return;
    _activeActionIndex = index;
    _clampIndex();
    notifyListeners();
    updateHomeWidget();
  }

  void _clampIndex() {
    final actions = activeActions;
    if (actions.isEmpty) {
      _activeActionIndex = 0;
    } else if (_activeActionIndex >= actions.length) {
      _activeActionIndex = actions.length - 1;
    }
    if (_activeActionIndex < 0) _activeActionIndex = 0;
  }

  void setStatsPeriod(int period) {
    _statsPeriod = period;
    // Always remember the last custom value if it's not a preset
    if (![7, 14, 30].contains(period)) {
      _customStatsPeriod = period;
    }
    _saveData();
    notifyListeners();
  }

  void setShowStats(bool value) {
    if (_showStats == value) return;
    _showStats = value;
    notifyListeners();
  }

  void toggleGoalsInstruction() {
    _showGoalsInstruction = !_showGoalsInstruction;
    _saveData();
    notifyListeners();
  }

  bool _isResetting = false;
  String _currentDateStr = '';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStates = prefs.getString('action_states_v2');
    final savedOrder = prefs.getStringList('action_order');
    final savedCustom = prefs.getString('custom_actions');
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('last_saved_date');

    final savedDeleted = prefs.getStringList('deleted_predefined_action_ids');

    _currentDateStr = savedDate ?? today;

    if (savedCustom != null) {
      final List<dynamic> decoded = jsonDecode(savedCustom);
      _customActions = decoded.map((item) => ActionConfig.fromJson(item)).toList();
    }

    if (savedDeleted != null) {
      _deletedPredefinedActionIds = savedDeleted;
    }

    if (savedOrder != null) {
      _actionOrder = savedOrder;
    }

    if (savedDate == null) {
      await prefs.setString('last_saved_date', today);
      _currentDateStr = today;
    }

    if (savedStates != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedStates);
      for (var entry in decoded.entries) {
        _actionStates[entry.key] = ActionData.fromJson(entry.value);
      }

      await checkAndResetDailyData();
      await syncFromWidget();
    }
    
    // Ensure all current baseActions (not deleted) and custom actions are in the order list
    final allActionIds = [
      ...baseActions.where((h) => !_deletedPredefinedActionIds.contains(h.id)).map((h) => h.id),
      ..._customActions.map((h) => h.id)
    ];
    for (var id in allActionIds) {
      if (!_actionOrder.contains(id)) {
        _actionOrder.add(id);
      }
    }

    // Remove any IDs in order that no longer exist
    _actionOrder.removeWhere((id) => !allActionIds.contains(id));
    
    _statsPeriod = prefs.getInt('stats_period') ?? 7;
    _customStatsPeriod = prefs.getInt('custom_stats_period') ?? 60;
    _showGoalsInstruction = prefs.getBool('show_goals_instruction') ?? true;
    
    // Fallback: Ensure at least one action is active
    if (!_actionStates.values.any((s) => s.isActive) && _actionOrder.isNotEmpty) {
      final firstId = _actionOrder[0];
      if (_actionStates[firstId] != null) {
        _actionStates[firstId]!.isActive = true;
      }
    }
    
    notifyListeners();
    await updateHomeWidget();
  }

  /// Checks if the date has changed since the last save and resets daily data if necessary.
  Future<bool> checkAndResetDailyData({bool force = false}) async {
    if (_isResetting) return false;

    final today = DateTime.now().toIso8601String().split('T')[0];
    
    // Use in-memory date if available, otherwise fetch from prefs (should overlap)
    if (_currentDateStr.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _currentDateStr = prefs.getString('last_saved_date') ?? today;
    }

    if (_currentDateStr != today || force) {
      _isResetting = true;
      try {
        // When forcing reset for testing, use yesterday's date to properly simulate midnight transition
        final String historyDateKey = force && _currentDateStr == today
            ? DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0]
            : _currentDateStr;
        
        debugPrint('📅 Date changed from $_currentDateStr to $today. Resetting daily data...');
        
        for (var state in _actionStates.values) {
          // Save final count of the previous day to history
          state.history = Map.from(state.history)..[historyDateKey] = state.count;
          
          state.count = 0;
          state.lastTapTime = null;
          // Recover to 1 credit only if it's currently 0
          if (state.resetCredits < 1) {
            state.resetCredits = 1;
          }
        }
        
        _currentDateStr = today;
        final prefs = await SharedPreferences.getInstance();
        await _saveData();
        await prefs.setString('last_saved_date', today);
        notifyListeners();
        await updateHomeWidget();
        return true;
      } finally {
        _isResetting = false;
      }
    }
    return false;
  }

  Future<void> updateHomeWidget() async {
    const groupId = 'group.com.pooha302.didit';
    await HomeWidget.setAppGroupId(groupId);
    
    // Get language for translations (respect app-level selection)
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('language_code');
    String langCode = savedLang ?? ui.PlatformDispatcher.instance.locale.languageCode.split('_')[0].split('-')[0].toLowerCase();
    
    final currentLang = AppLocaleProvider.translations.containsKey(langCode) ? langCode : 'en';

    // Filter active actions only for the widget
    final activeActionIds = _actionOrder.where((id) {
      final state = _actionStates[id];
      return state != null && state.isActive;
    }).toList();

    // Prepare JSON for grouped sync (more reliable on iOS)
    // ONLY include ACTIVE actions to fix the "inactive actions showing" issue
    final List<Map<String, dynamic>> activeActionsData = [];

    for (var actionId in activeActionIds) {
      final action = _actionStates[actionId]!;
      var baseAction = baseActions.firstWhere((a) => a.id == actionId, orElse: () => _customActions.firstWhere((a) => a.id == actionId, orElse: () => baseActions.first));
      final translatedTitle = AppLocaleProvider.translations[currentLang]?[baseAction.title] ?? baseAction.title;
      final hexColor = '#${baseAction.color.toARGB32().toRadixString(16).padLeft(8, '0')}';

      activeActionsData.add({
        'id': actionId,
        'title': translatedTitle,
        'count': action.count,
        'goal': action.goal,
        'color': hexColor,
      });

      // IMPORTANT: Also save individual keys so Widget-initiated increments and local reads match
      await HomeWidget.saveWidgetData<String>('title_$actionId', translatedTitle);
      await HomeWidget.saveWidgetData<int>('count_$actionId', action.count);
      await HomeWidget.saveWidgetData<int>('goal_$actionId', action.goal);
      await HomeWidget.saveWidgetData<String>('color_$actionId', hexColor);
    }

    // Save EVERYTHING into one atomic JSON string
    final jsonSync = jsonEncode(activeActionsData);
    await HomeWidget.saveWidgetData<String>('actions_json', jsonSync);
    
    // Save current selection and the list of IDs for legacy/compatibility
    await HomeWidget.saveWidgetData<String>('active_action_id', activeAction.id);
    await HomeWidget.saveWidgetData<String>('action_ids', activeActionIds.join(','));
    
    await HomeWidget.updateWidget(
      name: 'DidItWidgetProvider',
      androidName: 'DidItWidgetProvider',
      iOSName: 'ActionWidget',
    );
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_actionStates);
    await prefs.setString('action_states_v2', jsonString);
    await prefs.setStringList('action_order', _actionOrder);
    await prefs.setString('custom_actions', jsonEncode(_customActions.map((h) => h.toJson()).toList()));
    await prefs.setStringList('deleted_predefined_action_ids', _deletedPredefinedActionIds);
    await prefs.setInt('stats_period', _statsPeriod);
    await prefs.setInt('custom_stats_period', _customStatsPeriod);
    await prefs.setBool('show_goals_instruction', _showGoalsInstruction);
  }

  void reorderActions(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _actionOrder.removeAt(oldIndex);
    _actionOrder.insert(newIndex, item);
    
    AnalyticsService.instance.logReorderActions();

    _saveData();
    _clampIndex();
    notifyListeners();
    updateHomeWidget();
  }

  void addCustomAction(String title, IconData icon, Color color, {bool isPositiveGoal = true}) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newAction = ActionConfig(
      id: id,
      title: title,
      icon: icon,
      color: color,
      glowColor: color.withValues(alpha: 0.15),
      isCustom: true,
    );
    _customActions.add(newAction);
    _actionStates[id] = ActionData(isActive: true, isPositiveGoal: isPositiveGoal, goal: 0);
    _actionOrder.add(id);
    
    AnalyticsService.instance.logAddAction(
      actionId: id,
      actionName: title,
      iconCodePoint: icon.codePoint,
      colorHex: '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
      isPositiveGoal: isPositiveGoal,
    );

    _saveData();
    notifyListeners();
    updateHomeWidget();
  }

  void deleteAction(String id) {
    if (_actionOrder.length <= 1) return;

    final isPredefined = baseActions.any((h) => h.id == id);
    if (isPredefined) {
      if (!_deletedPredefinedActionIds.contains(id)) {
        _deletedPredefinedActionIds.add(id);
      }
    } else {
      _customActions.removeWhere((h) => h.id == id);
    }
    
    // Find name for logging before deletion
    final all = [...baseActions, ..._customActions];
    final action = all.firstWhere((h) => h.id == id, orElse: () => baseActions[0]);
    final actionName = action.title; // Note: this is the translation key or custom title

    _actionStates.remove(id);
    _actionOrder.remove(id);

    // If only 1 action remains, ensure it is active
    if (_actionOrder.length == 1) {
      final lastId = _actionOrder[0];
      if (_actionStates[lastId] != null) {
        _actionStates[lastId]!.isActive = true;
      }
    }

    AnalyticsService.instance.logDeleteAction(id, actionName);

    _saveData();
    _clampIndex();
    notifyListeners();
    updateHomeWidget();
  }

  void incrementActionCount(String id) {
    final state = _actionStates[id];
    if (state != null) {
      final now = DateTime.now();
      state.count++;
      state.lastTapTime = now;
      final today = now.toIso8601String().split('T')[0];
      state.history = Map.from(state.history)..[today] = state.count;
      _saveData();
      notifyListeners();
      updateHomeWidget();
    }
  }

  void resetCount() {
    if (activeState.resetCredits > 0) {
      activeState.count = 0;
      activeState.resetCredits--;
      activeState.lastTapTime = null;
      final today = DateTime.now().toIso8601String().split('T')[0];
      activeState.history = Map.from(activeState.history)..[today] = 0;
      
      AnalyticsService.instance.logResetAction(activeAction.id, activeAction.title);

      _saveData();
      notifyListeners();
      updateHomeWidget();
    }
  }

  void replenishResets() {
    activeState.resetCredits += 3;
    _saveData();
    notifyListeners();
  }

  List<int> getHistoryData(String id) {
    final state = _actionStates[id];
    if (state == null) return List.filled(_statsPeriod, 0);

    final List<int> data = [];
    final today = DateTime.now();
    
    for (int i = _statsPeriod - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i)).toIso8601String().split('T')[0];
      data.add(state.history[date] ?? 0);
    }
    return data;
  }

  void updateActionGoal(String id, int newGoal) {
    final state = _actionStates[id];
    if (state != null) {
      _actionStates[id] = state.copyWith(goal: newGoal);
      _saveData();
      notifyListeners();
      updateHomeWidget();
    }
  }

  void toggleGoalType(String id) {
    final state = _actionStates[id];
    if (state != null) {
      _actionStates[id] = state.copyWith(isPositiveGoal: !state.isPositiveGoal);
      
      AnalyticsService.instance.logGoalTypeChange(id, _actionStates[id]!.isPositiveGoal);

      _saveData();
      notifyListeners();
      updateHomeWidget();
    }
  }

  void toggleActionStatus(String id) {
    final state = _actionStates[id];
    if (state == null) return;

    if (state.isActive) {
      // Prevent deactivating if it's the last active action OR the only action period
      final activeCount = _actionStates.values.where((s) => s.isActive).length;
      if (activeCount <= 1 || _actionOrder.length <= 1) {
        return;
      }
      _actionStates[id] = state.copyWith(isActive: false);
    } else {
      _actionStates[id] = state.copyWith(isActive: true);
    }

    AnalyticsService.instance.logActionToggle(id, _actionStates[id]!.isActive);

    _saveData();
    _clampIndex();
    notifyListeners();
    updateHomeWidget();
  }

  void updateHistory(String id, DateTime date, int newCount) {
    final state = _actionStates[id];
    if (state == null) return;

    final dateStr = date.toIso8601String().split('T')[0];
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    // Update history
    state.history = Map.from(state.history)..[dateStr] = newCount;

    // If updating today, also update the main count
    if (dateStr == todayStr) {
      state.count = newCount;
    }

    _saveData();
    notifyListeners();
    updateHomeWidget();
  }

  Future<void> backupToCloud() async {
    try {
      final Map<String, dynamic> data = {
        'action_states_v2': _actionStates.map((key, value) => MapEntry(key, value.toJson())),
        'action_order': _actionOrder,
        'custom_actions': _customActions.map((h) => h.toJson()).toList(),
        'deleted_predefined_action_ids': _deletedPredefinedActionIds,
        'stats_period': _statsPeriod,
        'show_goals_instruction': _showGoalsInstruction,
        'version': 1,
      };

      await CloudBackupService.instance.backup(data);
      
      await AnalyticsService.instance.logCloudBackup(Platform.isAndroid ? 'Android' : 'iOS');
    } catch (e) {
      debugPrint('Backup Error: $e');
      rethrow;
    }
  }

  Future<bool> restoreFromCloud() async {
    try {
      final data = await CloudBackupService.instance.restore();
      if (data == null) return false;

      _restoreCustomActions(data);
      _restoreActionStates(data);
      _restoreDeletedIds(data);
      _restoreActionOrder(data);
      _restoreMetaSettings(data);

      await AnalyticsService.instance.logCloudRestore(Platform.isAndroid ? 'Android' : 'iOS');

      await _saveData();
      notifyListeners();
      await updateHomeWidget();
      return true;

    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }

  void _restoreCustomActions(Map<String, dynamic> data) {
    final customActionsData = data['custom_actions'];
    if (customActionsData is List) {
      _customActions = customActionsData
          .map((item) => ActionConfig.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  }

  void _restoreActionStates(Map<String, dynamic> data) {
    final statesData = data['action_states_v2'];
    if (statesData is Map<String, dynamic>) {
      for (var entry in statesData.entries) {
        _actionStates[entry.key] = ActionData.fromJson(entry.value);
      }
    }
  }

  void _restoreDeletedIds(Map<String, dynamic> data) {
    _restoreListField(data, 'deleted_predefined_action_ids', (list) {
      _deletedPredefinedActionIds = list;
    });
  }

  void _restoreActionOrder(Map<String, dynamic> data) {
    _restoreListField(data, 'action_order', (list) {
      _actionOrder = list;
    });
  }

  void _restoreListField(
    Map<String, dynamic> data,
    String key,
    void Function(List<String>) setter,
  ) {
    final listData = data[key];
    if (listData is List) {
      setter(List<String>.from(listData));
    }
  }

  void _restoreMetaSettings(Map<String, dynamic> data) {
    _statsPeriod = data['stats_period'] as int? ?? 7;
    _showGoalsInstruction = data['show_goals_instruction'] as bool? ?? true;
  }

  Future<void> resetToDefaults() async {
    // Reset to initial state
    _actionStates = {
      for (var action in baseActions)
        action.id: ActionData(
          isActive: action.id == 'coffee' || action.id == 'water',
          isPositiveGoal: action.id != 'coffee' && action.id != 'snack',
          goal: action.id == 'coffee' ? 3 : (action.id == 'water' ? 8 : 0),
        )
    };
    _actionOrder = baseActions.map((h) => h.id).toList();
    _customActions = [];
    _activeActionIndex = 0;
    _statsPeriod = 7;
    _showGoalsInstruction = true;
    _deletedPredefinedActionIds = [];

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Save initial state
    await _saveData();
    
    // Set initial date
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_saved_date', today);

    // Notify listeners to rebuild UI
    notifyListeners();
  }

  Future<void> syncFromWidget() async {
    const groupId = 'group.com.pooha302.didit';
    await HomeWidget.setAppGroupId(groupId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    
    bool hasChanges = false;

    // For Android (and generic fallback), sync from SharedPreferences first 
    // because background callback updates the shared JSON string.
    final savedStates = prefs.getString('action_states_v2');
    if (savedStates != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedStates);
      for (var entry in decoded.entries) {
        final newState = ActionData.fromJson(entry.value);
        final currentState = _actionStates[entry.key];
        
        // If the count on disk is higher than in memory, update memory
        if (currentState != null && newState.count > currentState.count) {
          _actionStates[entry.key] = newState;
          hasChanges = true;
        }
      }
    }
    
    // Original iOS-specific logic (individual keys check)
    if (Platform.isIOS) {
      for (var id in _actionStates.keys) {
        final state = _actionStates[id];
        if (state == null) continue;
        
        final widgetCount = await HomeWidget.getWidgetData<int>('count_$id');
        if (widgetCount != null && widgetCount > state.count) {
          state.count = widgetCount;
          
          // Read lastTapTime from widget data
          final widgetLastTapTime = await HomeWidget.getWidgetData<String>('lastTapTime_$id');
          if (widgetLastTapTime != null) {
            try {
              state.lastTapTime = DateTime.parse(widgetLastTapTime);
            } catch (e) {
              state.lastTapTime = DateTime.now(); // Fallback
            }
          } else {
            state.lastTapTime = DateTime.now(); // Fallback if not available
          }
          
          final today = DateTime.now().toIso8601String().split('T')[0];
          state.history = Map.from(state.history)..[today] = state.count;
          
          hasChanges = true;
        }
      }
    }
    
    if (hasChanges) {
      notifyListeners();
    }
  }

}
