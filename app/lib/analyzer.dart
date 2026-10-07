import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'logic.dart';
import 'models.dart';

/// 가화만사성과 같은 Supabase 프로젝트. Gemini 키는 서버 시크릿에만 있다.
const _functionUrl = 'https://lfruzdnubvluzsubnwsp.supabase.co/functions/v1/analyze-meal';
const _publishableKey = 'sb_publishable_r_Wu6YmTVtv1gIr0A-o54w_QdgSZbrC';

class MealAnalysis {
  const MealAnalysis({
    required this.category,
    required this.items,
    required this.servingOptions,
    required this.macroFeedback,
    required this.foodStory,
  });

  final String category;
  final List<MealItem> items;
  final List<List<int>> servingOptions;
  final String macroFeedback;
  final String foodStory;
}

class AnalysisException implements Exception {
  const AnalysisException(this.message);
  final String message;

  @override
  String toString() => message;
}

Future<MealAnalysis> analyzeMeal({required String imagePath, required String mealType, required String clientTime}) async {
  final bytes = await File(imagePath).readAsBytes();
  final http.Response response;
  try {
    response = await http
        .post(
          Uri.parse(_functionUrl),
          headers: {
            'Content-Type': 'application/json',
            'apikey': _publishableKey,
            'Authorization': 'Bearer $_publishableKey',
          },
          body: jsonEncode({
            'image_base64': base64Encode(bytes),
            'mime_type': imagePath.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
            'meal_type': mealType,
            'client_time': clientTime,
          }),
        )
        .timeout(const Duration(seconds: 45));
  } on SocketException {
    throw const AnalysisException('인터넷에 연결되지 않아 사진을 분석하지 못했어요.');
  } on Exception {
    throw const AnalysisException('분석이 오래 걸려 멈췄어요.');
  }
  if (response.statusCode != 200) {
    throw const AnalysisException('사진을 분석하지 못했어요.');
  }
  return parseAnalysis(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
}

MealAnalysis parseAnalysis(Map<String, dynamic> json) {
  if (json['recognized'] == false) {
    throw const AnalysisException('사진에서 음식을 찾지 못했어요.');
  }
  final items = <MealItem>[];
  for (final raw in (json['items'] as List?) ?? const []) {
    final item = Map<String, dynamic>.from(raw as Map);
    final choices = ((item['choices'] as List?) ?? const [])
        .map((choice) => FoodChoice.fromJson(Map<String, dynamic>.from(choice as Map)))
        .where((choice) => choice.name.isNotEmpty && choice.calories > 0)
        .toList();
    if (choices.isEmpty) continue;
    items.add(MealItem.recognized('${newId()}-${items.length}', item['question'] as String? ?? '', choices));
  }
  if (items.isEmpty) {
    throw const AnalysisException('사진에서 음식을 찾지 못했어요.');
  }
  final servings = ((json['estimated_servings_options'] as List?) ?? const [])
      .map((option) => (option as List).map((value) => (value as num).round()).toList())
      .where((option) => option.isNotEmpty)
      .toList();
  final category = json['category'] as String? ?? '';
  return MealAnalysis(
    category: categories.contains(category) ? category : '한식',
    items: items,
    servingOptions: servings.isEmpty
        ? [
            [1],
          ]
        : servings,
    macroFeedback: json['macro_feedback'] as String? ?? '',
    foodStory: json['food_story'] as String? ?? '',
  );
}
