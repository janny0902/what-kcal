import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store, required this.onWipe});

  final MealStore store;
  final VoidCallback onWipe;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        SoftCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                child: const Text('왓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이 기기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('기록 ${store.meals.length}개 · 이 폰에만 보관', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('데이터', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('계정이나 서버에는 기록을 올리지 않아요. 식사 기록은 이 앱 안에만 남고, 앱을 지우면 함께 사라집니다.', style: TextStyle(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('광고', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('계산하기를 누르면 애드몹 전면 광고가 나와요. 화면 아래에는 배너 광고가 있어요.', style: TextStyle(height: 1.5)),
              SizedBox(height: 6),
              Text('광고를 불러오지 못하면 기다리지 않고 결과로 이어져요.', style: TextStyle(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('식사 시간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('한국 시간으로 아침 5시, 아점 9시, 점심 11시, 점저 2시 30분, 저녁 5시, 그 외는 야식으로 나눠요. 결과에서 직접 바꿀 수 있어요.', style: TextStyle(height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onWipe,
          child: const Text('이 기기의 기록 모두 지우기', style: TextStyle(color: Color(0xFFE36B7A), fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
