import 'package:flutter/material.dart';
import 'package:nutri_tracker/features/food_tracking/models/food_item.dart';
import 'package:nutri_tracker/services/database_service.dart';

class FoodProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<FoodItem> _todaysFoods = [];
  Map<String, double> _dailyTotals = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };

  bool _isLoading = false;

  List<FoodItem> get todaysFoods => _todaysFoods;
  Map<String, double> get dailyTotals => _dailyTotals;
  bool get isLoading => _isLoading;

  Future<void> loadTodaysFoods() async {
    try {
      _isLoading = true;
      notifyListeners();

      _todaysFoods = await _databaseService.getFoodItemsByDate(DateTime.now());
      _dailyTotals = await _databaseService.getDailyTotals(DateTime.now());

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Erro ao carregar alimentos: $e');
      notifyListeners();
    }
  }

  Future<void> addFoodItem(FoodItem foodItem) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.insertFoodItem(foodItem);
      await loadTodaysFoods(); // Recarrega a lista

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Erro ao adicionar alimento: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFoodItem(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.deleteFoodItem(id);
      await loadTodaysFoods(); // Recarrega a lista

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Erro ao remover alimento: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<List<FoodItem>> getFoodsByDate(DateTime date) async {
    return await _databaseService.getFoodItemsByDate(date);
  }

  Future<Map<String, double>> getDailyTotalsByDate(DateTime date) async {
    return await _databaseService.getDailyTotals(date);
  }

  // Método para obter estatísticas dos últimos dias
  Future<Map<String, dynamic>> getWeeklyStats() async {
    Map<String, dynamic> stats = {
      'averageCalories': 0.0,
      'totalDays': 0,
      'daysWithData': 0,
    };

    try {
      double totalCalories = 0;
      int daysWithData = 0;

      for (int i = 0; i < 7; i++) {
        DateTime date = DateTime.now().subtract(Duration(days: i));
        Map<String, double> dayTotals = await getDailyTotalsByDate(date);

        if (dayTotals['calories']! > 0) {
          totalCalories += dayTotals['calories']!;
          daysWithData++;
        }
      }

      stats['averageCalories'] = daysWithData > 0
          ? totalCalories / daysWithData
          : 0.0;
      stats['totalDays'] = 7;
      stats['daysWithData'] = daysWithData;
    } catch (e) {
      print('Erro ao calcular estatísticas: $e');
    }

    return stats;
  }

  void clearData() {
    _todaysFoods.clear();
    _dailyTotals = {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    notifyListeners();
  }
}
