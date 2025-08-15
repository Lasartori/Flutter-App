import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nutri_tracker/features/food_tracking/models/food_item.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  void initialize() {
    final apiKey = dotenv.env['GOOGLE_AI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_AI_API_KEY não encontrada no arquivo .env');
    }

    _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);

    _isInitialized = true;
  }

  Future<List<FoodItem>> analyzeFoodImage(File imageFile) async {
    if (!_isInitialized || _model == null) {
      throw Exception(
        'AIService não foi inicializado. Chame initialize() primeiro.',
      );
    }

    try {
      final bytes = await imageFile.readAsBytes();

      final prompt = '''
      Analise esta imagem de comida e identifique todos os alimentos visíveis.
      Para cada alimento identificado, estime com base no que você pode ver na imagem:
      
      - Nome do alimento (em português)
      - Quantidade estimada em gramas (seja realista baseado no tamanho visual)
      - Calorias por porção estimada
      - Proteína em gramas
      - Carboidratos em gramas  
      - Gordura em gramas

      IMPORTANTE: Responda APENAS em formato JSON válido, como uma lista de objetos.
      Não adicione texto extra, comentários ou explicações. Apenas o JSON:

      [
        {
          "name": "nome do alimento",
          "portion": quantidade_em_gramas,
          "calories": calorias,
          "protein": proteinas_em_gramas,
          "carbs": carboidratos_em_gramas,
          "fat": gordura_em_gramas
        }
      ]

      Seja preciso nas estimativas nutricionais baseando-se em tabelas nutricionais padrão.
      Se não conseguir identificar claramente algum alimento, não o inclua na resposta.
      ''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)]),
      ];

      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      if (responseText.isEmpty) {
        throw Exception('Resposta vazia da IA');
      }

      return _parseAIResponse(responseText);
    } catch (e) {
      print('Erro na análise de IA: $e');
      rethrow;
    }
  }

  List<FoodItem> _parseAIResponse(String jsonResponse) {
    try {
      // Limpa a resposta removendo possíveis caracteres extras
      String cleanJson = jsonResponse.trim();

      // Remove blocos de código se existirem - CORREÇÃO AQUI
      if (cleanJson.contains('```json')) {
        // Extrai o conteúdo entre ```json e ```
        final startIndex = cleanJson.indexOf('```json') + 7;
        final endIndex = cleanJson.indexOf('```', startIndex);
        if (endIndex != -1) {
          cleanJson = cleanJson.substring(startIndex, endIndex).trim();
        }
      } else if (cleanJson.contains('```')) {
        // Extrai o conteúdo entre ```
        final parts = cleanJson.split('```');
        if (parts.length >= 2) {
          cleanJson = parts[1].trim();
        }
      }

      // Remove quebras de linha desnecessárias - CORREÇÃO AQUI
      cleanJson = cleanJson.replaceAll('\n', '').replaceAll('\r', '');

      final List<dynamic> jsonList = jsonDecode(cleanJson);

      return jsonList.map((item) {
        return FoodItem(
          name: item['name']?.toString() ?? 'Alimento não identificado',
          calories: _parseDouble(item['calories']),
          protein: _parseDouble(item['protein']),
          carbs: _parseDouble(item['carbs']),
          fat: _parseDouble(item['fat']),
          portion: _parseDouble(item['portion'], defaultValue: 100),
          unit: 'g',
          dateAdded: DateTime.now(),
          isAIDetected: true,
        );
      }).toList();
    } catch (e) {
      print('Erro ao processar resposta da IA: $e');
      print('Resposta original: $jsonResponse');
      throw Exception(
        'Não foi possível processar a resposta da IA. Tente novamente.',
      );
    }
  }

  double _parseDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Método para testar se a API está funcionando - CORREÇÃO AQUI
  Future<bool> testConnection() async {
    if (!_isInitialized || _model == null) return false;

    try {
      final response = await _model!.generateContent([
        Content.text('Responda apenas "OK" se você conseguir me ouvir.'),
      ]);

      return response.text?.trim().toLowerCase().contains('ok') ?? false;
    } catch (e) {
      print('Erro no teste de conexão: $e');
      return false;
    }
  }
}
