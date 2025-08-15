import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutri_tracker/features/user_profile/models/user_profile.dart';
import 'package:nutri_tracker/features/user_profile/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedGender = 'male';
  String _selectedActivityLevel = 'moderate';
  String _selectedGoal = 'maintain';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final userProfile = context.read<UserProvider>().userProfile;
    if (userProfile != null) {
      _nameController.text = userProfile.name;
      _ageController.text = userProfile.age.toString();
      _heightController.text = userProfile.height.toString();
      _weightController.text = userProfile.weight.toString();
      setState(() {
        _selectedGender = userProfile.gender;
        _selectedActivityLevel = userProfile.activityLevel;
        _selectedGoal = userProfile.goal;
      });
    }
  }

  double _calculateDailyCalorieGoal() {
    final age = int.tryParse(_ageController.text) ?? 25;
    final height = double.tryParse(_heightController.text) ?? 170;
    final weight = double.tryParse(_weightController.text) ?? 70;

    return context.read<UserProvider>().calculateDailyCalorieGoal(
      age: age,
      height: height,
      weight: weight,
      gender: _selectedGender,
      activityLevel: _selectedActivityLevel,
      goal: _selectedGoal,
    );
  }

  double _calculateBMI() {
    final height = double.tryParse(_heightController.text) ?? 170;
    final weight = double.tryParse(_weightController.text) ?? 70;
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25) return 'Peso normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidade';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
        goal: _selectedGoal,
        dailyCalorieGoal: _calculateDailyCalorieGoal(),
      );

      try {
        await context.read<UserProvider>().saveUserProfile(profile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil salvo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar perfil: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Card de informações pessoais
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações Pessoais',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira seu nome';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Idade',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.cake),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Insira a idade';
                                    }
                                    final age = int.tryParse(value);
                                    if (age == null || age < 1 || age > 120) {
                                      return 'Idade inválida';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedGender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gênero',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.wc),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Text('Masculino'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Text('Feminino'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _heightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Altura (cm)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.height),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Insira a altura';
                                    }
                                    final height = double.tryParse(value);
                                    if (height == null ||
                                        height < 50 ||
                                        height > 250) {
                                      return 'Altura inválida';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Peso (kg)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.monitor_weight),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Insira o peso';
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null ||
                                        weight < 20 ||
                                        weight > 300) {
                                      return 'Peso inválido';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de atividade e objetivos
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Atividade e Objetivos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedActivityLevel,
                            decoration: const InputDecoration(
                              labelText: 'Nível de Atividade',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.directions_run),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'sedentary',
                                child: Text(
                                  'Sedentário (pouco ou nenhum exercício)',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'light',
                                child: Text(
                                  'Pouco ativo (exercício leve 1-3 dias/semana)',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'moderate',
                                child: Text(
                                  'Moderadamente ativo (exercício moderado 3-5 dias/semana)',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'active',
                                child: Text(
                                  'Muito ativo (exercício intenso 6-7 dias/semana)',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'extra',
                                child: Text(
                                  'Extremamente ativo (exercício muito intenso, trabalho físico)',
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedActivityLevel = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            initialValue: _selectedGoal,
                            decoration: const InputDecoration(
                              labelText: 'Objetivo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'lose_weight',
                                child: Text('Perder peso'),
                              ),
                              DropdownMenuItem(
                                value: 'maintain',
                                child: Text('Manter peso'),
                              ),
                              DropdownMenuItem(
                                value: 'gain_weight',
                                child: Text('Ganhar peso'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGoal = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de métricas calculadas
                  if (_heightController.text.isNotEmpty &&
                      _weightController.text.isNotEmpty)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Métricas Calculadas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Meta Calórica Diária',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_calculateDailyCalorieGoal().toInt()} kcal',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _getBMIColor(
                                        _calculateBMI(),
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'IMC',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _calculateBMI().toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: _getBMIColor(
                                              _calculateBMI(),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _getBMICategory(_calculateBMI()),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _getBMIColor(
                                              _calculateBMI(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
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
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar Perfil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  if (userProvider.hasProfile) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteDialog(),
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir Perfil'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Perfil'),
        content: const Text(
          'Tem certeza que deseja excluir seu perfil? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<UserProvider>().deleteUserProfile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir perfil: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
