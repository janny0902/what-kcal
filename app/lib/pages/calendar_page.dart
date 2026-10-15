import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store, required this.onOpen, required this.onDelete});

  final MealStore store;
  final void Function(MealRecord meal) onOpen;
  final void Function(MealRecord meal) onDelete;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _cursor;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = seoulNow();
    _cursor = DateTime.utc(now.year, now.month);
    _selected = DateTime.utc(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final today = seoulStamp().date;
    final todayYmd = formatYmd(DateTime.utc(today.year, today.month, today.day));
    final selectedYmd = formatYmd(_selected);
    final totals = <String, int>{};
    for (final meal in widget.store.meals) {
      totals[meal.mealDate] = (totals[meal.mealDate] ?? 0) + eatenCalories(meal);
    }
    final sunday = _selected.subtract(Duration(days: _selected.weekday % 7));
    final week = List.generate(7, (index) => sunday.add(Duration(days: index)));
    final weekValues = week.map((day) => totals[formatYmd(day)] ?? 0).toList();
    final weekSum = weekValues.fold(0, (sum, value) => sum + value);
    final weekMax = weekValues.fold(0, (max, value) => value > max ? value : max);
    final ref = compareRefs[widget.store.compare]!;
    final weekGrams = weekValues.map((value) => value == 0 ? null : weightChangeGrams(value, ref.kcal)).toList();
    final weekGramSum = weekGrams.fold(0, (sum, value) => sum + (value ?? 0));
    final selectedMeals = widget.store.meals.where((meal) => meal.mealDate == selectedYmd).toList()..sort((a, b) => a.mealTime.compareTo(b.mealTime));
    final first = DateTime.utc(_cursor.year, _cursor.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
    final cells = List.generate(42, (index) => start.add(Duration(days: index)));
    const labels = ['일', '월', '화', '수', '목', '금', '토'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('주간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    '${week.first.month}월 ${week.first.day}일 – ${week.last.month}월 ${week.last.day}일',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 136,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = week[i]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: weekValues[i] == 0 ? 0.08 : (weekValues[i] / weekMax).clamp(0.12, 1.0),
                                    child: Container(
                                      width: 16,
                                      decoration: BoxDecoration(
                                        color: weekValues[i] == 0 ? const Color(0xFFEEF4F4) : null,
                                        gradient: weekValues[i] == 0
                                            ? null
                                            : const LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [Color(0xFF8FF6EA), AppColors.mint],
                                              ),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: formatYmd(week[i]) == selectedYmd ? FontWeight.w800 : FontWeight.w500,
                                  color: formatYmd(week[i]) == selectedYmd ? AppColors.mintDeep : AppColors.muted,
                                ),
                              ),
                              Text(
                                weekValues[i] == 0 ? '–' : comma(weekValues[i]),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: weekValues[i] == 0 ? AppColors.muted : AppColors.mintDeep),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat('누적', '${comma(weekSum)}kcal'),
                  const SizedBox(width: 8),
                  _stat('7일 평균', '${comma((weekSum / 7).round())}kcal'),
                  const SizedBox(width: 8),
                  _stat('누적 몸무게', signedGrams(weekGramSum), color: _gramColor(weekGrams.any((g) => g != null) ? weekGramSum : null)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${ref.label} ${comma(ref.kcal)}kcal 기준, 기록한 날만 계산해요. -는 감량, +는 증가예요.',
                style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  _nav(() => setState(() => _cursor = DateTime.utc(_cursor.year, _cursor.month - 1))),
                  Expanded(
                    child: Text(
                      '${_cursor.year}년 ${_cursor.month}월',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  _nav(() => setState(() => _cursor = DateTime.utc(_cursor.year, _cursor.month + 1)), next: true),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i == 0
                              ? AppColors.rose
                              : i == 6
                              ? AppColors.mintDeep
                              : AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final day in cells)
                    _cell(day, totals[formatYmd(day)] ?? 0, day.month == _cursor.month, formatYmd(day) == selectedYmd, formatYmd(day) == todayYmd),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(formatKoreanDate(_selected), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ),
        const SizedBox(height: 8),
        if (selectedMeals.isEmpty) const ChatBubble(child: Text('이 날은 아직 기록이 없어요.')),
        for (final meal in selectedMeals) MealCard(meal: meal, onOpen: () => widget.onOpen(meal), onDelete: () => widget.onDelete(meal)),
      ],
    );
  }

  Color _gramColor(int? grams) {
    if (grams == null || grams == 0) return AppColors.muted;
    return grams < 0 ? AppColors.mintDeep : AppColors.rose;
  }

  Widget _stat(String label, String value, {Color color = AppColors.ink}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav(VoidCallback onTap, {bool next = false}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(next ? Icons.chevron_right : Icons.chevron_left),
      style: IconButton.styleFrom(backgroundColor: AppColors.mintSoft),
    );
  }

  Widget _cell(DateTime day, int kcal, bool inMonth, bool selected, bool today) {
    return InkWell(
      onTap: () => setState(() => _selected = day),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? const [BoxShadow(color: Color(0x14283C3A), blurRadius: 8)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: today ? FontWeight.w800 : FontWeight.w500,
                color: inMonth ? (today ? AppColors.mintDeep : AppColors.ink) : const Color(0xFFC5D0D2),
              ),
            ),
            if (kcal > 0 && inMonth)
              Text(
                comma(kcal),
                style: const TextStyle(fontSize: 9, color: AppColors.mintDeep, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}
