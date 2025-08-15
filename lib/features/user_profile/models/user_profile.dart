class UserProfile {
  final int? id;
  final String name;
  final int age;
  final double height; // cm
  final double weight; // kg
  final String gender;
  final String activityLevel;
  final String goal; // lose_weight, maintain, gain_weight
  final double dailyCalorieGoal;

  UserProfile({
    this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dailyCalorieGoal,
  });

  // Cálculo de TMB usando fórmula de Harris-Benedict
  double get bmr {
    if (gender.toLowerCase() == 'male') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  double get bmi {
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    double bmiValue = bmi;
    if (bmiValue < 18.5) return 'Abaixo do peso';
    if (bmiValue < 25) return 'Peso normal';
    if (bmiValue < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
      'dailyCalorieGoal': dailyCalorieGoal,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      height: map['height'].toDouble(),
      weight: map['weight'].toDouble(),
      gender: map['gender'],
      activityLevel: map['activityLevel'],
      goal: map['goal'],
      dailyCalorieGoal: map['dailyCalorieGoal'].toDouble(),
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? activityLevel,
    String? goal,
    double? dailyCalorieGoal,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
    );
  }
}
