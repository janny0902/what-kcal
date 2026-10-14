import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatkcal/analyzer.dart';
import 'package:whatkcal/logic.dart';
import 'package:whatkcal/models.dart';
import 'package:whatkcal/pages/archive_page.dart';
import 'package:whatkcal/pages/calendar_page.dart';
import 'package:whatkcal/shell.dart';
import 'package:whatkcal/store.dart';

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

  test('1,000kcal는 130g, 기준보다 적게 먹으면 감량으로 보인다', () {
    expect(gramsFromKcal(1000), 130);
    expect(weightChangeGrams(1500, 2000), -65);
    expect(signedGrams(weightChangeGrams(1500, 2000)), '-65g');
    expect(signedGrams(weightChangeGrams(2770, 2000)), '+100g');
  });

  test('점심 분석은 저녁 가이드와 운동을 함께 받는다', () {
    final analysis = parseAnalysis({
      'items': [
        {
          'choices': [
            {'name': '탕수육', 'calories': 780},
          ],
        },
      ],
      'next_guide': {'title': '저녁은 채소 위주로', 'body': '점심 튀김으로 지방을 많이 드셨어요.'},
      'exercise': {'name': '빠르게 걷기', 'minutes': 40, 'calories': 200},
    });
    expect(analysis.guideTitle, '저녁은 채소 위주로');
    expect(analysis.exerciseKcal, 200);
    expect(gramsFromKcal(analysis.exerciseKcal), 26);
  });

  test('음식이 없는 사진은 분석 실패로 넘긴다', () {
    expect(() => parseAnalysis({'recognized': false, 'items': []}), throwsA(isA<AnalysisException>()));
  });

  MealStore todayStore() {
    final now = seoulStamp();
    return MealStore()
      ..helloSeen = true
      ..meals = [
        MealRecord(
          id: 'l',
          mealDate: now.mealDate,
          mealTime: '12:10:00',
          mealType: '점심',
          category: '중식',
          items: [MealItem(id: 'a', name: '탕수육', portion: '1접시', calories: 1000, description: '')],
          servingOptions: [
            [1],
          ],
          servingIndex: 0,
          macroFeedback: '',
          foodStory: '',
          imagePath: '',
          recordedLabel: '',
          updatedAt: 0,
          guideTitle: '저녁은 채소 위주로',
          guideBody: '점심 튀김으로 지방을 많이 드셨어요.',
          exerciseName: '빠르게 걷기',
          exerciseMinutes: 40,
          exerciseKcal: 200,
        ),
      ];
  }

  testWidgets('기록 탭은 오늘 감량 g와 식사별 가이드를 보여 준다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ArchivePage(store: todayStore(), onOpen: (_) {}))));
    expect(find.text('오늘 다이어트 성공'), findsOneWidget);
    expect(find.text('-130g'), findsOneWidget);
    expect(find.text('저녁은 채소 위주로'), findsOneWidget);
    expect(find.text('26g 더 감량'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('달력 주간에 누적 몸무게가 나온다', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CalendarPage(store: todayStore(), onOpen: (_) {}, onDelete: (_) {}))));
    expect(find.text('누적 몸무게'), findsOneWidget);
    expect(find.text('-130g'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('카메라 버튼을 누르면 식단 사진 시트가 열린다', variant: TargetPlatformVariant.only(TargetPlatform.linux), (tester) async {
    final store = MealStore()..helloSeen = true;
    await tester.pumpWidget(WhatKcalApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('camera-fab')));
    await tester.pumpAndSettle();

    expect(find.text('식단 사진'), findsOneWidget);
    expect(find.text('카메라로 찍기'), findsOneWidget);
    expect(find.text('앨범에서 고르기'), findsOneWidget);
  });
}
