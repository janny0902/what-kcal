import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key, required this.store, required this.onOpen, required this.onDelete});

  final MealStore store;
  final void Function(MealRecord meal) onOpen;
  final void Function(MealRecord meal) onDelete;

  @override
  Widget build(BuildContext context) {
    if (store.meals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ChatBubble(child: Text('아직 남긴 식사가 없어요. 카메라로 첫 기록을 만들어 보세요.')),
      );
    }
    final groups = <String, List<MealRecord>>{};
    for (final meal in store.meals) {
      groups.putIfAbsent(meal.mealDate, () => []).add(meal);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        for (final date in dates) ...[
          Center(child: Text(_label(date), style: const TextStyle(color: AppColors.muted, fontSize: 12))),
          const SizedBox(height: 8),
          for (final meal in (groups[date]!..sort((a, b) => a.mealTime.compareTo(b.mealTime))))
            MealCard(meal: meal, onOpen: () => onOpen(meal), onDelete: () => onDelete(meal)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _label(String ymd) {
    final parts = ymd.split('-').map(int.parse).toList();
    return formatKoreanDate(DateTime.utc(parts[0], parts[1], parts[2]));
  }
}
