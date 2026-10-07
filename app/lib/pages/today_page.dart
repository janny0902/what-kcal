import 'dart:io';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key, required this.store, required this.onOpen, required this.onDelete});

  final MealStore store;
  final void Function(MealRecord meal) onOpen;
  final void Function(MealRecord meal) onDelete;

  @override
  Widget build(BuildContext context) {
    final today = seoulStamp().mealDate;
    final todays = store.meals.where((meal) => meal.mealDate == today).toList()
      ..sort((a, b) => a.mealTime.compareTo(b.mealTime));
    final total = todays.fold(0, (sum, meal) => sum + eatenCalories(meal));
    final hero = todays.reversed.cast<MealRecord?>().firstWhere(
          (meal) => meal != null && meal.imagePath.isNotEmpty && File(meal.imagePath).existsSync(),
          orElse: () => null,
        );
    final ref = compareRefs[store.compare]!;
    final ratio = ref.kcal == 0 ? 0.0 : (total / ref.kcal).clamp(0.0, 1.0);
    final diff = ref.kcal - total;
    var copy = '오늘 기록을 시작하면 막대가 채워져요.';
    if (total > 0 && diff.abs() <= 50) {
      copy = '${ref.label} 참고치와 비슷해요.';
    } else if (total > 0 && diff > 0) {
      copy = '${ref.label} 참고치까지 ${comma(diff)}kcal 남았어요.';
    } else if (total > 0) {
      copy = '${ref.label} 참고치보다 ${comma(diff.abs())}kcal 더 기록됐어요.';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 196,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hero != null) Image.file(File(hero.imagePath), fit: BoxFit.cover) else const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7AF0E4), AppColors.mint, AppColors.mintDeep]),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x140A2826), Color(0x8C0A2826)]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatKoreanDate(seoulStamp().date), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: comma(total), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w700, height: 1)),
                        const TextSpan(text: ' kcal', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ])),
                      const SizedBox(height: 8),
                      Text(todays.isEmpty ? '오늘의 첫 식사를 남겨 보세요' : '오늘 ${todays.length}끼를 남겼어요', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('참고치와 비교', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final key in compareRefs.keys)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text(key),
                          selected: store.compare == key,
                          onSelected: (_) => store.setCompare(key),
                          selectedColor: AppColors.mint,
                          backgroundColor: AppColors.mintSoft,
                          labelStyle: TextStyle(color: store.compare == key ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13),
                          showCheckmark: false,
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : ratio,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFEEF4F4),
                  color: total > ref.kcal ? AppColors.rose : AppColors.mint,
                ),
              ),
              const SizedBox(height: 8),
              Text(copy, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${ref.label} ${comma(ref.kcal)}kcal · ${ref.note}', style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (todays.isEmpty) const ChatBubble(child: Text('오늘 식사는 아직 없어요. 가운데 카메라로 사진을 올려 주세요.')),
        for (final meal in todays) ...[
          MealCard(meal: meal, onOpen: () => onOpen(meal), onDelete: () => onDelete(meal)),
        ],
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('칼로리는 추정치예요. 진료나 식단 처방을 대신하지 않아요.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
      ],
    );
  }
}
