import 'package:flutter_test/flutter_test.dart';
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
}
