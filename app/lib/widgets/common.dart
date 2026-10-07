import 'dart:io';

import 'package:flutter/material.dart';

import '../logic.dart';
import '../models.dart';
import '../theme.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
        boxShadow: const [BoxShadow(color: Color(0x10283C3A), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
          child: const Text('왓', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: const [BoxShadow(color: Color(0x10283C3A), blurRadius: 14, offset: Offset(0, 4))],
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.meal, required this.onOpen, required this.onDelete});

  final MealRecord meal;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final file = meal.imagePath.isEmpty ? null : File(meal.imagePath);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Material(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(6),
          ),
          child: InkWell(
            onTap: onOpen,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: file != null && file.existsSync()
                          ? Image.file(file, fit: BoxFit.cover)
                          : const ColoredBox(color: AppColors.mintSoft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mealTitle(meal), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.mintSoft, borderRadius: BorderRadius.circular(99)),
                          child: Text(meal.mealType, style: const TextStyle(color: AppColors.mintDeep, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 4),
                        Text(meal.category, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(comma(eatenCalories(meal)), style: const TextStyle(color: AppColors.mintDeep, fontSize: 18, fontWeight: FontWeight.w700)),
                      const Text('kcal', style: TextStyle(color: AppColors.mintDeep, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        TextButton(onPressed: onDelete, child: const Text('지우기', style: TextStyle(color: AppColors.muted, fontSize: 12))),
      ],
    );
  }
}

class MintButton extends StatelessWidget {
  const MintButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: onPressed == null
              ? const LinearGradient(colors: [Color(0xFFB7E6E0), Color(0xFFB7E6E0)])
              : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3ADCCB), AppColors.mint]),
          boxShadow: onPressed == null ? null : const [BoxShadow(color: Color(0x4714C4B4), blurRadius: 16, offset: Offset(0, 8))],
        ),
        child: TextButton(
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
