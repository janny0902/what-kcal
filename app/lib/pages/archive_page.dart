import 'dart:io';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 오늘 하루 식사마다 다음 행동 가이드와 몸무게 환산을 보여 준다.
class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key, required this.store, required this.onOpen});

  final MealStore store;
  final void Function(MealRecord meal) onOpen;

  @override
  Widget build(BuildContext context) {
    final today = seoulStamp().mealDate;
    final todays = store.meals.where((meal) => meal.mealDate == today).toList()..sort((a, b) => a.mealTime.compareTo(b.mealTime));
    final ref = compareRefs[store.compare]!;
    final total = todays.fold(0, (sum, meal) => sum + eatenCalories(meal));
    final change = weightChangeGrams(total, ref.kcal);
    final exerciseKcal = todays.fold(0, (sum, meal) => sum + _guide(meal).exerciseKcal);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(
          child: Text(formatKoreanDate(seoulStamp().date), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
        const SizedBox(height: 12),
        if (todays.isEmpty)
          const ChatBubble(child: Text('오늘 첫 식사를 찍으면 몇 g 다이어트했는지와 다음 식사·운동 가이드를 알려 드려요.'))
        else ...[
          _summary(total, ref, change, exerciseKcal),
          const SizedBox(height: 12),
          for (final meal in todays) ...[_mealGuide(meal), const SizedBox(height: 12)],
        ],
        const Text(
          '체지방 1kg ≈ 7,700kcal(1,000kcal ≈ 130g)로 환산한 추정치예요. 기준은 오늘 탭에서 고른 참고치예요. 진료나 처방을 대신하지 않아요.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _summary(int total, CompareRef ref, int change, int exerciseKcal) {
    final lost = change <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lost ? const [Color(0xFF3ADCCB), Color(0xFF13C3B3)] : const [Color(0xFFF59AA6), AppColors.rose],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lost ? '오늘 다이어트 성공' : '오늘 기준보다 더 드셨어요',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          Text(
            signedGrams(change),
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700, height: 1.2),
          ),
          Text('섭취 ${comma(total)}kcal · ${ref.label} 기준 ${comma(ref.kcal)}kcal', style: const TextStyle(color: Colors.white, fontSize: 13)),
          if (exerciseKcal > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(99)),
              child: Text(
                '추천 운동을 모두 하면 ${comma(gramsFromKcal(exerciseKcal))}g 더 뺄 수 있어요 → ${signedGrams(change - gramsFromKcal(exerciseKcal))}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealGuide(MealRecord meal) {
    final guide = _guide(meal);
    final file = meal.imagePath.isEmpty ? null : File(meal.imagePath);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onOpen(meal),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: file != null && file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const ColoredBox(color: AppColors.mintSoft),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(99)),
                            child: Text(
                              meal.mealType,
                              style: const TextStyle(color: AppColors.mintDeep, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(meal.mealTime.substring(0, 5), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mealTitle(meal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${comma(eatenCalories(meal))}kcal',
                  style: const TextStyle(color: AppColors.mintDeep, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 22, color: AppColors.line),
          Text(
            guide.title,
            style: const TextStyle(color: AppColors.mintDeep, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(guide.body, style: const TextStyle(height: 1.5)),
          if (guide.exerciseKcal > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.directions_run, color: AppColors.mintDeep, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${guide.exerciseName}${guide.exerciseMinutes > 0 ? ' ${guide.exerciseMinutes}분' : ''} · ${comma(guide.exerciseKcal)}kcal',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${comma(gramsFromKcal(guide.exerciseKcal))}g 더 감량',
                    style: const TextStyle(color: AppColors.mintDeep, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// AI 가이드가 없는 기록(직접 입력, 이전 버전)은 식사 구분에 맞춘 기본 안내를 쓴다.
  _Guide _guide(MealRecord meal) {
    if (meal.guideBody.isNotEmpty) {
      return _Guide(
        meal.guideTitle.isEmpty ? '다음 행동' : meal.guideTitle,
        meal.guideBody,
        meal.exerciseName.isEmpty ? '운동' : meal.exerciseName,
        meal.exerciseMinutes,
        meal.exerciseKcal,
      );
    }
    return switch (meal.mealType) {
      '아침' || '아점' => const _Guide('점심은 균형 있게', '밥 양을 먼저 정하고 단백질 반찬과 채소를 곁들여 드세요.', '빠르게 걷기', 20, 100),
      '점심' || '점저' => const _Guide('저녁은 가볍게', '저녁은 기름을 줄이고 채소와 두부, 생선 위주로 가볍게 드세요.', '빠르게 걷기', 30, 150),
      _ => const _Guide('식후 가볍게 움직이기', '늦은 시간 식사는 소화가 더뎌요. 식후 가볍게 걷고, 잠들기 2~3시간 전에는 더 먹지 않는 게 좋아요.', '빠르게 걷기', 30, 150),
    };
  }
}

class _Guide {
  const _Guide(this.title, this.body, this.exerciseName, this.exerciseMinutes, this.exerciseKcal);

  final String title;
  final String body;
  final String exerciseName;
  final int exerciseMinutes;
  final int exerciseKcal;
}
