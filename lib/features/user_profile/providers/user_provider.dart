import 'package:flutter/material.dart';
import 'package:nutri_tracker/features/user_profile/models/user_profile.dart';
import 'package:nutri_tracker/services/database_service.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get hasProfile => _userProfile != null;

  Future<void> loadUserProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      _userProfile = await _databaseService.getUserProfile();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Erro ao carregar perfil: $e');
      notifyListeners();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_userProfile == null) {
        await _databaseService.insertUserProfile(profile);
      } else {
        final updatedProfile = profile.copyWith(id: _userProfile!.id);
        await _databaseService.updateUserProfile(updatedProfile);
      }

      await loadUserProfile();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Erro ao salvar perfil: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUserProfile() async {
    if (_userProfile?.id == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.deleteUserProfile(_userProfile!.id!);
      _userProfile = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      print('Erro ao deletar perfil: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Método para calcular meta calórica automaticamente
  double calculateDailyCalorieGoal({
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    // Cálculo BMR (Harris-Benedict)
    double bmr;
    if (gender.toLowerCase() == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Multiplicador de atividade
    double activityMultiplier;
    switch (activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'extra':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    double dailyCalories = bmr * activityMultiplier;

    // Ajuste baseado no objetivo
    switch (goal) {
      case 'lose_weight':
        dailyCalories -= 500; // Déficit de 500 calorias
        break;
      case 'gain_weight':
        dailyCalories += 500; // Superávit de 500 calorias
        break;
      default:
        break; // Manter peso
    }

    return dailyCalories;
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
