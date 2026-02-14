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

    test('checkAndResetDailyData should reset counts automatically during initialization', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
      
      // Save data from yesterday (simulate old data being present before app start)
      final states = {
        'coffee': ActionData(count: 5, isActive: true).toJson()
      };
      await prefs.setString('action_states_v2', jsonEncode(states));
      await prefs.setString('last_saved_date', yesterday);
      
      // Act: Initialization triggers checkAndResetDailyData via _init
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));

      // Assert: It should have reset automatically
      expect(provider.actionStates['coffee']!.count, 0);
      expect(provider.actionStates['coffee']!.history[yesterday], 5);
      expect(prefs.getString('last_saved_date'), today);
    });

    test('Incrementing should NOT trigger reset if already reset today', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));
      
      provider.actionStates['coffee']!.count = 2; // Simulate some counts today
      
      // Act: User taps coffee today
      await provider.incrementActionCount('coffee');
      
      // Assert: It should NOT reset (count should be 3, not 1)
      expect(provider.actionStates['coffee']!.count, 3);
      expect(prefs.getString('last_saved_date'), today);
    });

    test('resetCredits should be replenished during automatic initialization reset', () async {
      final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
      
      final states = {
        'coffee': ActionData(count: 5, isActive: true, resetCredits: 0).toJson() // Used credit yesterday
      };
      await prefs.setString('action_states_v2', jsonEncode(states));
      await prefs.setString('last_saved_date', yesterday);
      
      // Act: Initialization triggers reset
      final provider = ActionProvider();
      await Future.delayed(Duration(milliseconds: 100));
      
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
      
      // It should have detected missing date (internal fallback to 2000-01-01) and reset
      expect(provider.actionStates['coffee']!.count, 0);
      expect(prefs.getString('last_saved_date'), today);
    });
  });
}
