import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/action.dart';
import '../services/cloud_backup_service.dart';
import '../services/analytics_service.dart';

class ActionProvider with ChangeNotifier {
  Map<String, ActionData> _actionStates = {
    for (var action in ACTIONS)
      action.id: ActionData(
        isActive: action.id == 'coffee' || action.id == 'water',
        isPositiveGoal: action.id != 'coffee' && action.id != 'snack',
        goal: action.id == 'coffee' ? 3 : (action.id == 'water' ? 8 : 0),
      )
  };
  List<String> _actionOrder = ACTIONS.map((h) => h.id).toList();
  List<ActionConfig> _customActions = [];

  int _activeActionIndex = 0;
  int _statsPeriod = 7;
  bool _showGoalsInstruction = true;
  bool _showStats = false;
  List<String> _deletedPredefinedActionIds = [];

  Map<String, ActionData> get actionStates => _actionStates;
  int get activeActionIndex => _activeActionIndex;
  List<String> get actionOrder => _actionOrder;
  int get statsPeriod => _statsPeriod;
  bool get showGoalsInstruction => _showGoalsInstruction;
  bool get showStats => _showStats;
  
  List<ActionConfig> get allActionsByOrder {
    final all = [...ACTIONS, ..._customActions];
    return _actionOrder
        .map((id) => all.firstWhere((h) => h.id == id, orElse: () => ACTIONS[0]))
        .toList();
  }

  List<ActionConfig> get activeActions => allActionsByOrder.where((h) => _actionStates[h.id]?.isActive ?? false).toList();
  
  ActionConfig get activeAction {
    final actions = activeActions;
    if (actions.isEmpty) return ACTIONS[0];
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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStates = prefs.getString('action_states_v2');
    final savedOrder = prefs.getStringList('action_order');
    final savedCustom = prefs.getString('custom_actions');
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('last_saved_date');

    final savedDeleted = prefs.getStringList('deleted_predefined_action_ids');

    // Load custom actions
    if (savedCustom != null) {
      final List<dynamic> decoded = jsonDecode(savedCustom);
      _customActions = decoded.map((item) => ActionConfig.fromJson(item)).toList();
    }

    // Load deleted predefined ids
    if (savedDeleted != null) {
      _deletedPredefinedActionIds = savedDeleted;
    }

    // Load custom order if exists
    if (savedOrder != null) {
      _actionOrder = savedOrder;
    }

    // Initialize last saved date if it's the first run
    if (savedDate == null) {
      await prefs.setString('last_saved_date', today);
    }

    if (savedStates != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedStates);
      for (var entry in decoded.entries) {
        _actionStates[entry.key] = ActionData.fromJson(entry.value);
      }

      // Handle daily reset logic
      if (savedDate != null && savedDate != today) {
        for (var state in _actionStates.values) {
          state.count = 0;
          // Recover to 1 credit only if it's currently 0
          if (state.resetCredits < 1) {
            state.resetCredits = 1;
          }
        }
        await _saveData();
        await prefs.setString('last_saved_date', today);
      }
    }
    
    // Ensure all current ACTIONS (not deleted) and custom actions are in the order list
    final allActionIds = [
      ...ACTIONS.where((h) => !_deletedPredefinedActionIds.contains(h.id)).map((h) => h.id),
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
    _showGoalsInstruction = prefs.getBool('show_goals_instruction') ?? true;
    
    // Fallback: Ensure at least one action is active
    if (!_actionStates.values.any((s) => s.isActive) && _actionOrder.isNotEmpty) {
      final firstId = _actionOrder[0];
      if (_actionStates[firstId] != null) {
        _actionStates[firstId]!.isActive = true;
      }
    }
    
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_actionStates);
    await prefs.setString('action_states_v2', jsonString);
    await prefs.setStringList('action_order', _actionOrder);
    await prefs.setString('custom_actions', jsonEncode(_customActions.map((h) => h.toJson()).toList()));
    await prefs.setStringList('deleted_predefined_action_ids', _deletedPredefinedActionIds);
    await prefs.setInt('stats_period', _statsPeriod);
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
  }

  void addCustomAction(String title, IconData icon, Color color, {bool isPositiveGoal = true}) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newAction = ActionConfig(
      id: id,
      title: title,
      icon: icon,
      color: color,
      glowColor: color.withOpacity(0.15),
      isCustom: true,
    );
    _customActions.add(newAction);
    _actionStates[id] = ActionData(isActive: true, isPositiveGoal: isPositiveGoal, goal: 0);
    _actionOrder.add(id);
    
    AnalyticsService.instance.logAddAction(
      actionId: id,
      actionName: title,
      iconCodePoint: icon.codePoint,
      colorHex: '#${color.value.toRadixString(16).padLeft(8, '0')}',
      isPositiveGoal: isPositiveGoal,
    );

    _saveData();
    notifyListeners();
  }

  void deleteAction(String id) {
    if (_actionOrder.length <= 1) return;

    final isPredefined = ACTIONS.any((h) => h.id == id);
    if (isPredefined) {
      if (!_deletedPredefinedActionIds.contains(id)) {
        _deletedPredefinedActionIds.add(id);
      }
    } else {
      _customActions.removeWhere((h) => h.id == id);
    }
    
    // Find name for logging before deletion
    final all = [...ACTIONS, ..._customActions];
    final action = all.firstWhere((h) => h.id == id, orElse: () => ACTIONS[0]);
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
  }

  void incrementActionCount(String id) {
    final state = _actionStates[id];
    if (state != null) {
      state.count++;
      final today = DateTime.now().toIso8601String().split('T')[0];
      state.history = Map.from(state.history)..[today] = state.count;
      _saveData();
      notifyListeners();
    }
  }

  void resetCount() {
    if (activeState.resetCredits > 0) {
      activeState.count = 0;
      activeState.resetCredits--;
      final today = DateTime.now().toIso8601String().split('T')[0];
      activeState.history = Map.from(activeState.history)..[today] = 0;
      
      AnalyticsService.instance.logResetAction(activeAction.id, activeAction.title);

      _saveData();
      notifyListeners();
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
    }
  }

  void toggleGoalType(String id) {
    final state = _actionStates[id];
    if (state != null) {
      _actionStates[id] = state.copyWith(isPositiveGoal: !state.isPositiveGoal);
      
      AnalyticsService.instance.logGoalTypeChange(id, _actionStates[id]!.isPositiveGoal);

      _saveData();
      notifyListeners();
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
      
      AnalyticsService.instance.logCloudBackup(Platform.isAndroid ? 'Android' : 'iOS');
    } catch (e) {
      debugPrint('Backup Error: $e');
      rethrow;
    }
  }

  Future<bool> restoreFromCloud() async {
    try {
      final data = await CloudBackupService.instance.restore();
      if (data == null) return false;

      // Handle custom actions
      if (data['custom_actions'] != null) {
        final List<dynamic> decoded = data['custom_actions'];
        _customActions = decoded.map((item) => ActionConfig.fromJson(item)).toList();
      }

      // Handle action states
      if (data['action_states_v2'] != null) {
        final Map<String, dynamic> states = data['action_states_v2'];
        for (var entry in states.entries) {
          _actionStates[entry.key] = ActionData.fromJson(entry.value);
        }
      }

      // Handle deleted predefined IDs
      if (data['deleted_predefined_action_ids'] != null) {
        _deletedPredefinedActionIds = List<String>.from(data['deleted_predefined_action_ids']);
      }

      // Handle order
      if (data['action_order'] != null) {
        _actionOrder = List<String>.from(data['action_order']);
      }

      // Meta settings
      _statsPeriod = data['stats_period'] ?? 7;
      _showGoalsInstruction = data['show_goals_instruction'] ?? true;

      AnalyticsService.instance.logCloudRestore(Platform.isAndroid ? 'Android' : 'iOS');

      await _saveData();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Restore Error: $e');
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    // Reset to initial state
    _actionStates = {
      for (var action in ACTIONS)
        action.id: ActionData(
          isActive: action.id == 'coffee' || action.id == 'water',
          isPositiveGoal: action.id != 'coffee' && action.id != 'snack',
          goal: action.id == 'coffee' ? 3 : (action.id == 'water' ? 8 : 0),
        )
    };
    _actionOrder = ACTIONS.map((h) => h.id).toList();
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

}
