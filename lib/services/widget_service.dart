import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  const groupId = 'group.com.pooha302.didit';
  await HomeWidget.setAppGroupId(groupId);

  // 1. Handle Navigation (Cycle through actions)
  if (uri?.host == 'cycle') {
    final currentId = uri?.queryParameters['id'];
    final widgetId = uri?.queryParameters['widgetId'];
    final direction = uri?.queryParameters['dir'];
    final actionOrderStr = await HomeWidget.getWidgetData<String>('action_ids');
    
    if (actionOrderStr != null && widgetId != null) {
      final order = actionOrderStr.split(',');
      int currentIndex = order.indexOf(currentId ?? '');
      if (currentIndex == -1) currentIndex = 0;

      int nextIndex;
      if (direction == 'next') {
        nextIndex = (currentIndex + 1) % order.length;
      } else {
        nextIndex = (currentIndex - 1 + order.length) % order.length;
      }

      final nextActionId = order[nextIndex];
      // Save specific selection for THIS widget instance
      await HomeWidget.saveWidgetData<String>('selected_id_$widgetId', nextActionId);
      
      await HomeWidget.updateWidget(
        name: 'DidItWidgetProvider',
        androidName: 'DidItWidgetProvider',
        iOSName: 'ActionWidget',
      );
    }
    return;
  }

  // 2. Handle Increment
  if (uri?.host == 'increment') {
    String? targetId = uri?.queryParameters['id'];
    
    final savedStates = prefs.getString('action_states_v2');
    if (savedStates != null) {
      final Map<String, dynamic> states = jsonDecode(savedStates);
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastSavedDate = prefs.getString('last_saved_date');
      
      if (lastSavedDate != null && lastSavedDate != today) {
        debugPrint('WIDGET: Date changed from $lastSavedDate to $today. Resetting all counts...');
        
        for (var entry in states.entries) {
          final stateMap = entry.value;
          final history = Map<String, dynamic>.from(stateMap['history'] ?? {});
          
          history[lastSavedDate] = stateMap['count'] ?? 0;
          stateMap['history'] = history;
          stateMap['count'] = 0;
          stateMap['lastTapTime'] = null;
          
          if ((stateMap['resetCredits'] ?? 0) < 1) {
            stateMap['resetCredits'] = 1;
          }
          
          await HomeWidget.saveWidgetData<int>('count_${entry.key}', 0);
        }
        
        await prefs.setString('action_states_v2', jsonEncode(states));
        await prefs.setString('last_saved_date', today);
      }
      
      if (targetId == null || !states.containsKey(targetId)) {
        for (var entry in states.entries) {
           if (entry.value['isActive'] == true) {
             targetId = entry.key;
             break;
           }
        }
      }

      if (targetId != null) {
        final stateMap = states[targetId];
        stateMap['count'] = (stateMap['count'] ?? 0) + 1;
        stateMap['lastTapTime'] = DateTime.now().toIso8601String();
        
        final history = Map<String, dynamic>.from(stateMap['history'] ?? {});
        history[today] = stateMap['count'];
        stateMap['history'] = history;
        
        await prefs.setString('action_states_v2', jsonEncode(states));
        await HomeWidget.saveWidgetData<int>('count_$targetId', stateMap['count']);
        
        if (targetId == (await HomeWidget.getWidgetData<String>('active_action_id'))) {
            await HomeWidget.saveWidgetData<int>('count', stateMap['count']);
        }

        await HomeWidget.updateWidget(
          name: 'DidItWidgetProvider',
          androidName: 'DidItWidgetProvider',
          iOSName: 'ActionWidget',
        );
      }
    }
  }
}
