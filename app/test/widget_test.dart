import 'package:flutter_test/flutter_test.dart';
import 'package:whatkcal/analyzer.dart';
import 'package:whatkcal/logic.dart';
import 'package:whatkcal/models.dart';

void main() {
  test('점심 시간대는 점심으로 나눈다', () {
    expect(detectMealType('12:27:00'), '점심');
    expect(detectMealType('09:30:00'), '아점');
    expect(detectMealType('22:10:00'), '야식');
  });

  test('2~3인분은 사진 칼로리를 나눠 내 섭취가 된다', () {
    final meal = MealRecord(
      id: '1',
      mealDate: '2026-10-07',
      mealTime: '12:00:00',
      mealType: '점심',
      category: '분식',
      items: [MealItem(id: 'a', name: '김밥', portion: '1줄', calories: 450, description: '')],
      servingOptions: [
        [1],
        [2, 3],
      ],
      servingIndex: 1,
      macroFeedback: '',
      foodStory: '',
      imagePath: '',
      recordedLabel: '',
      updatedAt: 0,
    );
    expect(eatenCalories(meal), 180);
  });

  test('헷갈리는 튀김은 후보를 고르면 칼로리가 바뀐다', () {
    final analysis = parseAnalysis({
      'recognized': true,
      'category': '중식',
      'items': [
        {
          'question': '어떤 튀김인가요?',
          'choices': [
            {'label': '돼지고기', 'name': '탕수육', 'portion': '1접시', 'calories': 780, 'description': ''},
            {'label': '닭고기', 'name': '깐풍기', 'portion': '1접시', 'calories': 650, 'description': ''},
          ],
        },
      ],
      'estimated_servings_options': [
        [1],
        [2, 3],
      ],
    });
    final item = analysis.items.single;
    expect(analysis.category, '중식');
    expect(item.name, '탕수육');
    expect(item.calories, 780);
    item.choose(1);
    expect(item.name, '깐풍기');
    expect(item.calories, 650);
    final restored = MealItem.fromJson(item.toJson());
    expect(restored.choices.length, 2);
    expect(restored.choiceIndex, 1);
  });

  test('음식이 없는 사진은 분석 실패로 넘긴다', () {
    expect(() => parseAnalysis({'recognized': false, 'items': []}), throwsA(isA<AnalysisException>()));
  });
}
