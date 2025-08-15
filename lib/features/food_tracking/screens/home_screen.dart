import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutri_tracker/features/food_tracking/providers/food_provider.dart';
import 'package:nutri_tracker/features/user_profile/providers/user_provider.dart';
import 'package:nutri_tracker/features/food_tracking/models/food_item.dart';
import 'package:nutri_tracker/features/user_profile/models/user_profile.dart';
import 'add_food_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().loadTodaysFoods();
      context.read<UserProvider>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriTracker'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HistoryScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<FoodProvider, UserProvider>(
        builder: (context, foodProvider, userProvider, child) {
          if (foodProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final dailyTotals = foodProvider.dailyTotals;
          final calorieGoal =
              userProvider.userProfile?.dailyCalorieGoal ?? 2000;

          return RefreshIndicator(
            onRefresh: () async {
              await foodProvider.loadTodaysFoods();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mensagem de boas-vindas
                  if (!userProvider.hasProfile) _buildWelcomeCard(),

                  // Card de Resumo Diário
                  _buildDailySummaryCard(dailyTotals, calorieGoal),
                  const SizedBox(height: 20),

                  // Botões de Ação
                  _buildActionButtons(),
                  const SizedBox(height: 20),

                  // Lista de Alimentos do Dia
                  _buildTodaysFoodsList(foodProvider.todaysFoods),
                  const SizedBox(height: 20),

                  // Resumo Nutricional e Sugestões
                  if (foodProvider.todaysFoods.isNotEmpty)
                    _buildNutritionalAnalysis(
                      dailyTotals,
                      userProvider.userProfile,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.waving_hand, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            const Text(
              'Bem-vindo ao NutriTracker!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure seu perfil para receber recomendações personalizadas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              ),
              child: const Text('Configurar Perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(Map<String, double> totals, double goal) {
    final caloriesConsumed = totals['calories'] ?? 0;
    final progress = caloriesConsumed / goal;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Resumo de Hoje',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Progresso de Calorias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calorias:', style: TextStyle(fontSize: 16)),
                Text(
                  '${caloriesConsumed.toInt()} / ${goal.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress > 1 ? 1 : progress,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 1 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),

            // Macronutrientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroColumn(
                  'Proteína',
                  totals['protein'] ?? 0,
                  'g',
                  Colors.blue,
                ),
                _buildMacroColumn(
                  'Carbs',
                  totals['carbs'] ?? 0,
                  'g',
                  Colors.orange,
                ),
                _buildMacroColumn(
                  'Gordura',
                  totals['fat'] ?? 0,
                  'g',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroColumn(
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text('$label ($unit)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddFoodScreen(isManual: true),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Manual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddFoodScreen(isManual: false),
              ),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto com IA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysFoodsList(List<FoodItem> foods) {
    if (foods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Nenhum alimento adicionado hoje.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Comece adicionando sua primeira refeição!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alimentos de Hoje (${foods.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...foods.map((food) => _buildFoodTile(food)).toList(),
      ],
    );
  }

  Widget _buildFoodTile(FoodItem food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: food.isAIDetected ? Colors.green : Colors.blue,
          child: Icon(
            food.isAIDetected ? Icons.smart_toy : Icons.restaurant,
            color: Colors.white,
          ),
        ),
        title: Text(
          food.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${food.portion.toInt()}g -  ${food.calories.toInt()} kcal',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${food.protein.toInt()}P | ${food.carbs.toInt()}C | ${food.fat.toInt()}G',
              style: const TextStyle(fontSize: 11),
            ),
            if (food.id != null)
              GestureDetector(
                onTap: () => _showDeleteDialog(food),
                child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(FoodItem food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Alimento'),
        content: Text('Deseja remover "${food.name}" da sua lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<FoodProvider>().removeFoodItem(food.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alimento removido com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao remover alimento: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalAnalysis(
    Map<String, double> totals,
    UserProfile? profile,
  ) {
    if (profile == null) {
      return Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Análise Nutricional',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '📋 Configure seu perfil para receber análises personalizadas da sua alimentação.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                ),
                child: const Text('Configurar Perfil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final caloriesConsumed = totals['calories'] ?? 0;
    final proteinConsumed = totals['protein'] ?? 0;
    final carbsConsumed = totals['carbs'] ?? 0;
    final fatConsumed = totals['fat'] ?? 0;

    // Cálculos de recomendações baseados no perfil
    final proteinRecommended = profile.weight * 1.2; // 1.2g por kg
    final fatRecommended =
        profile.dailyCalorieGoal * 0.25 / 9; // 25% das calorias
    final carbsRecommended =
        (profile.dailyCalorieGoal -
            (proteinRecommended * 4) -
            (fatRecommended * 9)) /
        4;

    List<String> suggestions = [];

    // Análise e sugestões
    if (caloriesConsumed > profile.dailyCalorieGoal * 1.1) {
      suggestions.add(
        '⚠️ Você está consumindo mais calorias que o recomendado. Considere porções menores.',
      );
    } else if (caloriesConsumed < profile.dailyCalorieGoal * 0.8) {
      suggestions.add(
        '📈 Suas calorias estão baixas. Adicione alguns lanches saudáveis.',
      );
    }

    if (proteinConsumed < proteinRecommended * 0.8) {
      suggestions.add(
        '🥩 Aumente o consumo de proteínas: ovos, carnes magras, legumes.',
      );
    }

    if (fatConsumed < fatRecommended * 0.7) {
      suggestions.add('🥑 Inclua gorduras saudáveis: abacate, nozes, azeite.');
    }

    if (carbsConsumed > carbsRecommended * 1.3) {
      suggestions.add('🍞 Reduza carboidratos refinados, prefira integrais.');
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        '🎉 Excelente! Sua alimentação está bem equilibrada hoje.',
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análise Nutricional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...suggestions
                .map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
