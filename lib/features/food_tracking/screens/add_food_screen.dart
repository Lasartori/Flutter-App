import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nutri_tracker/features/food_tracking/models/food_item.dart';
import 'package:nutri_tracker/features/food_tracking/providers/food_provider.dart';
import 'package:nutri_tracker/services/ai_service.dart';

class AddFoodScreen extends StatefulWidget {
  final bool isManual;

  const AddFoodScreen({Key? key, required this.isManual}) : super(key: key);

  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _portionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final AIService _aiService = AIService();

  File? _selectedImage;
  List<FoodItem> _aiDetectedFoods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isManual) {
      _pickImageAndAnalyze();
    }
    // Valores padrão
    _portionController.text = '100';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndAnalyze() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isLoading = true;
        });

        final detectedFoods = await _aiService.analyzeFoodImage(
          _selectedImage!,
        );

        setState(() {
          _aiDetectedFoods = detectedFoods;
          _isLoading = false;
        });

        if (detectedFoods.isEmpty) {
          _showErrorDialog(
            'Não foi possível identificar alimentos na imagem. '
            'Tente outra foto com boa iluminação ou adicione manualmente.',
          );
        }
      } else {
        // Usuário cancelou
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao analisar a imagem: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFoodItem(FoodItem foodItem) async {
    try {
      await context.read<FoodProvider>().addFoodItem(foodItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alimento adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erro ao salvar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isManual ? 'Adicionar Manual' : 'Analisar com IA'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Analisando imagem...'),
                  SizedBox(height: 8),
                  Text(
                    'Isso pode levar alguns segundos',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : widget.isManual
          ? _buildManualForm()
          : _buildAIResults(),
    );
  }

  Widget _buildManualForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações do Alimento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Alimento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.restaurant),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome do alimento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _portionController,
                            decoration: const InputDecoration(
                              labelText: 'Porção (g)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insira a porção';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration: const InputDecoration(
                              labelText: 'Calorias',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.local_fire_department),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insira as calorias';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Número inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Macronutrientes (opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            decoration: const InputDecoration(
                              labelText: 'Proteína (g)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.fitness_center),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            decoration: const InputDecoration(
                              labelText: 'Carbs (g)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.grain),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            decoration: const InputDecoration(
                              labelText: 'Gordura (g)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.opacity),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveManualFood,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Alimento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResults() {
    if (_aiDetectedFoods.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_food, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Nenhum alimento detectado',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tente uma foto com boa iluminação\ne foque nos alimentos',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickImageAndAnalyze,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFoodScreen(isManual: true),
                  ),
                ),
                child: const Text('Adicionar Manualmente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_selectedImage != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _aiDetectedFoods.length,
            itemBuilder: (context, index) {
              final food = _aiDetectedFoods[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
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
                              food.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: const Text('IA'),
                            backgroundColor: Colors.green,
                            avatar: const Icon(Icons.smart_toy, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Porção: ${food.portion.toInt()}g'),
                                Text(
                                  'Calorias: ${food.calories.toInt()} kcal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildNutrientInfo(
                                  'Proteína',
                                  food.protein,
                                  Colors.blue,
                                ),
                                _buildNutrientInfo(
                                  'Carbs',
                                  food.carbs,
                                  Colors.orange,
                                ),
                                _buildNutrientInfo(
                                  'Gordura',
                                  food.fat,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _saveFoodItem(food),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Este Alimento'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickImageAndAnalyze,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Nova Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _aiDetectedFoods.isNotEmpty
                      ? () async {
                          for (var food in _aiDetectedFoods) {
                            await _saveFoodItem(food);
                            // Pequena pausa para não sobrecarregar
                            await Future.delayed(
                              const Duration(milliseconds: 100),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Adicionar Todos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text('$label (g)', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _saveManualFood() {
    if (_formKey.currentState!.validate()) {
      final foodItem = FoodItem(
        name: _nameController.text,
        calories: double.parse(_caloriesController.text),
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        portion: double.parse(_portionController.text),
        unit: 'g',
        dateAdded: DateTime.now(),
        isAIDetected: false,
      );

      _saveFoodItem(foodItem);
    }
  }
}
