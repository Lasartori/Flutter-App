import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nutri_tracker/features/food_tracking/providers/food_provider.dart';
import 'package:nutri_tracker/features/user_profile/providers/user_provider.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DateTime> _last30Days = [];
  Map<DateTime, Map<String, double>> _monthlyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateLast30Days();
    _loadMonthlyData();
  }

  void _generateLast30Days() {
    _last30Days.clear();
    final today = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      _last30Days.add(DateTime(today.year, today.month, today.day - i));
    }
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;
    });

    final foodProvider = context.read<FoodProvider>();

    for (DateTime date in _last30Days) {
      try {
        final totals = await foodProvider.getDailyTotalsByDate(date);
        _monthlyData[date] = totals;
      } catch (e) {
        print('Erro ao carregar dados para $date: $e');
        _monthlyData[date] = {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        };
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      return 'Hoje';
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(yesterday)) {
      return 'Ontem';
    } else {
      return DateFormat('dd/MM - EEEE', 'pt_BR').format(date);
    }
  }

  Map<String, double> _calculateWeeklyAverage() {
    if (_monthlyData.isEmpty) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int daysWithData = 0;

    final last7Days = _last30Days.take(7);

    for (DateTime date in last7Days) {
      final dayData = _monthlyData[date];
      if (dayData != null && dayData['calories']! > 0) {
        totalCalories += dayData['calories']!;
        totalProtein += dayData['protein']!;
        totalCarbs += dayData['carbs']!;
        totalFat += dayData['fat']!;
        daysWithData++;
      }
    }

    if (daysWithData == 0) {
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'calories': totalCalories / daysWithData,
      'protein': totalProtein / daysWithData,
      'carbs': totalCarbs / daysWithData,
      'fat': totalFat / daysWithData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMonthlyData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final calorieGoal =
                    userProvider.userProfile?.dailyCalorieGoal ?? 2000;
                final weeklyAverage = _calculateWeeklyAverage();

                return RefreshIndicator(
                  onRefresh: _loadMonthlyData,
                  child: Column(
                    children: [
                      // Card de resumo semanal
                      _buildWeeklySummaryCard(weeklyAverage, calorieGoal),

                      // Lista de dias
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _last30Days.length,
                          itemBuilder: (context, index) {
                            final date = _last30Days[index];
                            final totals =
                                _monthlyData[date] ??
                                {
                                  'calories': 0,
                                  'protein': 0,
                                  'carbs': 0,
                                  'fat': 0,
                                };

                            return _buildDayCard(date, totals, calorieGoal);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildWeeklySummaryCard(
    Map<String, double> weeklyAverage,
    double calorieGoal,
  ) {
    final avgCalories = weeklyAverage['calories'] ?? 0;
    final progress = avgCalories / calorieGoal;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Média dos Últimos 7 Dias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeeklyStat(
                    'Calorias',
                    avgCalories,
                    'kcal',
                    Colors.white,
                  ),
                  _buildWeeklyStat(
                    'Proteína',
                    weeklyAverage['protein'] ?? 0,
                    'g',
                    Colors.white,
                  ),
                  _buildWeeklyStat(
                    'Carbs',
                    weeklyAverage['carbs'] ?? 0,
                    'g',
                    Colors.white,
                  ),
                  _buildWeeklyStat(
                    'Gordura',
                    weeklyAverage['fat'] ?? 0,
                    'g',
                    Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de progresso da meta
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Meta Calórica Média:',
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress > 1 ? 1 : progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 1 ? Colors.orange : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyStat(
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildDayCard(
    DateTime date,
    Map<String, double> totals,
    double calorieGoal,
  ) {
    final isToday =
        DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final caloriesConsumed = totals['calories'] ?? 0;
    final progress = caloriesConsumed / calorieGoal;
    final hasData = caloriesConsumed > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isToday ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: Colors.green, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.green : Colors.black87,
                      ),
                    ),
                  ),
                  if (!hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Sem dados',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),

              if (hasData) ...[
                const SizedBox(height: 12),

                // Progresso de Calorias
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calorias:', style: TextStyle(fontSize: 14)),
                    Text(
                      '${caloriesConsumed.toInt()} / ${calorieGoal.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress > 1 ? 1 : progress,
                  backgroundColor: Colors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 1.2
                        ? Colors.red
                        : progress > 1
                        ? Colors.orange
                        : progress > 0.8
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),

                // Macronutrientes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroInfo(
                      'Proteína',
                      totals['protein'] ?? 0,
                      Colors.blue,
                    ),
                    _buildMacroInfo(
                      'Carbs',
                      totals['carbs'] ?? 0,
                      Colors.orange,
                    ),
                    _buildMacroInfo(
                      'Gordura',
                      totals['fat'] ?? 0,
                      Colors.purple,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Nenhum alimento registrado neste dia',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text('$label (g)', style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
