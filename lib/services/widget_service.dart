import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  debugPrint('WIDGET: Background callback triggered with URI: $uri');
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
      
      debugPrint('WIDGET: Cycled widget $widgetId to $nextActionId');
      
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
    // If targeted, use the ID from URI. If not, fallback to active one.
    String? targetId = uri?.queryParameters['id'];
    
    final savedStates = prefs.getString('action_states_v2');
    if (savedStates != null) {
      final Map<String, dynamic> states = jsonDecode(savedStates);
      
      if (targetId == null || !states.containsKey(targetId)) {
        // Fallback: Find current active action in app
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
        
        final today = DateTime.now().toIso8601String().split('T')[0];
        final history = Map<String, dynamic>.from(stateMap['history'] ?? {});
        history[today] = stateMap['count'];
        stateMap['history'] = history;
        
        await prefs.setString('action_states_v2', jsonEncode(states));

        // Sync back to Widget individual data
        await HomeWidget.saveWidgetData<int>('count_$targetId', stateMap['count']);
        
        // Also sync to legacy keys just in case
        if (targetId == (await HomeWidget.getWidgetData<String>('active_action_id'))) {
            await HomeWidget.saveWidgetData<int>('count', stateMap['count']);
        }

        debugPrint('WIDGET: Incremented $targetId to ${stateMap['count']}');

        await HomeWidget.updateWidget(
          name: 'DidItWidgetProvider',
          androidName: 'DidItWidgetProvider',
          iOSName: 'ActionWidget',
        );
      }
    }
  }
}
