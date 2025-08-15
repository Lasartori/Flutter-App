class FoodItem {
  final int? id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double portion;
  final String unit;
  final DateTime dateAdded;
  final String? imageUrl;
  final bool isAIDetected;

  FoodItem({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.portion,
    required this.unit,
    required this.dateAdded,
    this.imageUrl,
    this.isAIDetected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'portion': portion,
      'unit': unit,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'isAIDetected': isAIDetected ? 1 : 0,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      calories: map['calories'].toDouble(),
      protein: map['protein'].toDouble(),
      carbs: map['carbs'].toDouble(),
      fat: map['fat'].toDouble(),
      portion: map['portion'].toDouble(),
      unit: map['unit'],
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['dateAdded']),
      imageUrl: map['imageUrl'],
      isAIDetected: map['isAIDetected'] == 1,
    );
  }

  FoodItem copyWith({
    int? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? portion,
    String? unit,
    DateTime? dateAdded,
    String? imageUrl,
    bool? isAIDetected,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      portion: portion ?? this.portion,
      unit: unit ?? this.unit,
      dateAdded: dateAdded ?? this.dateAdded,
      imageUrl: imageUrl ?? this.imageUrl,
      isAIDetected: isAIDetected ?? this.isAIDetected,
    );
  }
}
