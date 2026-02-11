import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:didit/providers/action_provider.dart';
import 'package:didit/models/action.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActionProvider Daily Reset Tests', () {
    late SharedPreferences prefs;

    // Mock HomeWidget platform channel to avoid errors
    const MethodChannel homeWidgetChannel = MethodChannel('home_widget');
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // Mock any method call to home_widget channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        homeWidgetChannel,
        (MethodCall methodCall) async {
          return null;
        },
      );
    });

    test('Initial loading should set today date if not present', () async {
      final provider = ActionProvider();
      // wait for _loadData to complete
      await Future.delayed(Duration(milliseconds: 100));
      
      final today = DateTime.now().toIso8601String().split('T')[0];
      expect(prefs.getString('last_saved_date'), today);
    });

    test('checkAndResetDailyData should reset counts if date has changed', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
      
      // Set initial values in prefs
      await prefs.setString('last_saved_date', yesterday);
      
      // ActionProvider initialization will trigger _loadData which calls checkAndResetDailyData
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));

      // Manually add some count for coffee
      final coffeeState = provider.actionStates['coffee']!;
      coffeeState.count = 5;
      coffeeState.isActive = true;
      
      // Now intentionally call checkAndResetDailyData with a different current state
      // (Provider thinks it's yesterday because we set it in prefs before init)
      
      // Act: Date changes to today
      final didReset = await provider.checkAndResetDailyData();
      
      // Assert
      expect(didReset, isTrue);
      expect(provider.actionStates['coffee']!.count, 0);
      expect(provider.actionStates['coffee']!.history[yesterday], 5);
      expect(prefs.getString('last_saved_date'), today);
    });

    test('Incrementing should trigger reset if date changed since last tap', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
      
      await prefs.setString('last_saved_date', yesterday);
      
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));
      
      // Simulate coffee being active but at count 5 yesterday (which hasn't been reset yet in memory)
      provider.actionStates['coffee']!.count = 5;
      
      // Act: User taps coffee today
      await provider.incrementActionCount('coffee');
      
      // Assert: It should have reset (to 0) then incremented (to 1)
      expect(provider.actionStates['coffee']!.count, 1);
      expect(provider.actionStates['coffee']!.history[yesterday], 5);
      expect(prefs.getString('last_saved_date'), today);
    });

    test('resetCredits should be replenished to 1 on daily reset if it was 0', () async {
      final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
      await prefs.setString('last_saved_date', yesterday);
      
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));
      
      // Yesterday user used their reset
      provider.actionStates['coffee']!.resetCredits = 0;
      
      // Act: Daily reset happens
      await provider.checkAndResetDailyData();
      
      // Assert: Credit should be back to 1
      expect(provider.actionStates['coffee']!.resetCredits, 1);
    });

    test('Migration: Reset should occur if last_saved_date is missing but data exists', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Save data but NO date (to simulate older version)
      final states = {
        'coffee': ActionData(count: 7, isActive: true).toJson()
      };
      await prefs.setString('action_states_v2', jsonEncode(states));
      
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));
      
      // It should have detected missing date and force-reset
      expect(provider.actionStates['coffee']!.count, 0);
      expect(prefs.getString('last_saved_date'), today);
    });
  });
}
