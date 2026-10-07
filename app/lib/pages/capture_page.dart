import 'dart:io';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CapturePage extends StatelessWidget {
  const CapturePage({super.key, required this.imagePath, required this.mealType, required this.onMealType});

  final String imagePath;
  final String mealType;
  final ValueChanged<String> onMealType;

  @override
  Widget build(BuildContext context) {
    final now = seoulStamp();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(child: Text(recordedLabel(now.mealDate, now.mealTime, mealType), style: const TextStyle(color: AppColors.muted, fontSize: 12))),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(File(imagePath), height: 220, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('식사', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('지금 시간 기준은 ${detectMealType(now.mealTime)}이에요. 다르게 남기려면 눌러 바꾸세요.', style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final type in mealTypes)
                    ChoiceChip(
                      label: Text(type),
                      selected: mealType == type,
                      onSelected: (_) => onMealType(type),
                      selectedColor: AppColors.mint,
                      backgroundColor: AppColors.mintSoft,
                      labelStyle: TextStyle(color: mealType == type ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700),
                      showCheckmark: false,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
