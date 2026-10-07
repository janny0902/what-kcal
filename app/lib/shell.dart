import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ads.dart';
import 'analyzer.dart';
import 'logic.dart';
import 'models.dart';
import 'pages/archive_page.dart';
import 'pages/calendar_page.dart';
import 'pages/capture_page.dart';
import 'pages/result_page.dart';
import 'pages/settings_page.dart';
import 'pages/today_page.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets/common.dart';

class WhatKcalApp extends StatelessWidget {
  const WhatKcalApp({super.key, required this.store});

  final MealStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '왓칼로리',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: _WhatKcalShell(store: store),
    );
  }
}

class _WhatKcalShell extends StatefulWidget {
  const _WhatKcalShell({required this.store});

  final MealStore store;

  @override
  State<_WhatKcalShell> createState() => _WhatKcalShellState();
}

class _WhatKcalShellState extends State<_WhatKcalShell> {
  int _tab = 0;
  int _backTab = 0;
  String? _imagePath;
  String _captureType = '점심';
  MealRecord? _draft;
  bool _busy = false;
  bool _fallback = false;
  bool _analyzing = false;
  String? _analysisNotice;
  bool _askedHello = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    super.dispose();
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  bool get _onTabs => _imagePath == null && _draft == null && !_fallback && !_analyzing;

  @override
  Widget build(BuildContext context) {
    if (!_askedHello && !widget.store.helloSeen) {
      _askedHello = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _hello());
    }
    final now = seoulStamp();
    final titles = [
      ('왓칼로리', formatKoreanDate(now.date)),
      ('달력', '주간과 월간'),
      ('기록', '이 기기에 남긴 식사'),
      ('설정', '이 폰'),
    ];
    final title = _draft != null
        ? ('분석 결과', '확인하고 이 기기에 저장해요')
        : _imagePath != null
            ? ('식단 올리기', '계산 전 식사를 확인해요')
            : titles[_tab];

    return PopScope(
      canPop: _onTabs,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leaveOverlay();
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ColoredBox(
                color: AppColors.bg,
                child: Column(
                  children: [
                    _header(title.$1, title.$2, showBack: !_onTabs),
                    Expanded(child: _body()),
                    if (_fallback)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('광고를 불러오지 못했어요. 결과를 이어갈게요.', textAlign: TextAlign.center),
                      ),
                    if (_draft != null || _onTabs)
                      const Padding(padding: EdgeInsets.only(top: 6), child: AdmobBanner()),
                    if (_imagePath != null && _draft == null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Column(
                          children: [
                            MintButton(label: _analyzing ? '분석 중' : _busy ? '광고 준비 중' : '계산하기', onPressed: _busy ? null : _calculate),
                            const SizedBox(height: 6),
                            const Text('광고가 나오는 동안 AI가 사진 속 음식을 분석해요.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    if (_draft != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: MintButton(label: '이 기기에 저장', onPressed: hasValidItem(_draft!) ? _save : null),
                      ),
                    if (_onTabs) _tabs(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final draft = _draft;
    if (_fallback) {
      return const Center(child: CircularProgressIndicator(color: AppColors.mint));
    }
    if (_analyzing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.mint),
            SizedBox(height: 14),
            Text('사진 속 음식을 분석하고 있어요', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }
    if (draft != null) {
      return ResultPage(draft: draft, notice: _analysisNotice, onChanged: (next) => setState(() => _draft = next));
    }
    final image = _imagePath;
    if (image != null) {
      return CapturePage(imagePath: image, mealType: _captureType, onMealType: (type) => setState(() => _captureType = type));
    }
    return switch (_tab) {
      0 => TodayPage(store: widget.store, onOpen: _edit, onDelete: _askDelete),
      1 => CalendarPage(store: widget.store, onOpen: _edit, onDelete: _askDelete),
      2 => ArchivePage(store: widget.store, onOpen: _edit, onDelete: _askDelete),
      _ => SettingsPage(store: widget.store, onWipe: _askWipe),
    };
  }

  Widget _header(String title, String subtitle, {required bool showBack}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.headerTop, AppColors.mint]),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: _leaveOverlay,
              icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
            )
          else
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.favorite, color: Colors.white, size: 18),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Padding(
          padding: EdgeInsets.only(top: 8, bottom: bottomInset > 8 ? bottomInset : 8),
          child: SizedBox(
            height: 58,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _tabButton(0, Icons.home_outlined, '오늘'),
                    _tabButton(1, Icons.calendar_month_outlined, '달력'),
                    const Expanded(child: SizedBox.shrink()),
                    _tabButton(2, Icons.format_list_bulleted, '기록'),
                    _tabButton(3, Icons.person_outline, '설정'),
                  ],
                ),
                Material(
                  color: AppColors.mint,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    key: const Key('camera-fab'),
                    customBorder: const CircleBorder(),
                    onTap: _pickPhoto,
                    child: const SizedBox(
                      width: 58,
                      height: 58,
                      child: Icon(Icons.photo_camera_outlined, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    final on = _tab == index;
    final color = on ? AppColors.mintDeep : const Color(0xFF9AA7A8);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _hello() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 폰에만 남아요', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('식사 기록은 이 앱 안에만 저장돼요. 계정은 없고, 앱을 지우면 기록도 함께 사라집니다. 사진은 계산할 때 AI 분석에만 보내고 서버에 남기지 않아요.', style: TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            MintButton(label: '알겠어요', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
    await widget.store.markHello();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('식단 사진', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('카메라로 찍거나 앨범에서 고르면, 계산 전에 광고가 나와요.'),
            const SizedBox(height: 12),
            MintButton(label: '카메라로 찍기', onPressed: () => Navigator.pop(context, ImageSource.camera)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('앨범에서 고르기', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 82);
    if (picked == null || !mounted) return;
    final stored = await widget.store.persistImage(picked.path);
    if (!mounted) return;
    setState(() {
      _backTab = _tab;
      _imagePath = stored;
      _captureType = detectMealType(seoulStamp().mealTime);
      _draft = null;
    });
  }

  Future<void> _calculate() async {
    final image = _imagePath;
    if (image == null || _busy) return;
    final now = seoulStamp();
    setState(() {
      _busy = true;
      _analysisNotice = null;
    });
    final analysis = analyzeMeal(imagePath: image, mealType: _captureType, clientTime: '${now.mealDate} ${now.mealTime}')
        .then<Object>((value) => value, onError: (Object error) => error);
    final shown = await showInterstitial();
    if (!mounted) return;
    if (!shown) {
      setState(() => _fallback = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
    }
    setState(() {
      _fallback = false;
      _analyzing = true;
    });
    final outcome = await analysis;
    if (!mounted) return;
    final result = outcome is MealAnalysis ? outcome : null;
    setState(() {
      _busy = false;
      _analyzing = false;
      _analysisNotice = result == null
          ? '${outcome is AnalysisException ? outcome.message : '사진을 분석하지 못했어요.'} 음식을 고르거나 직접 입력해 주세요.'
          : null;
      _draft = MealRecord(
        id: newId(),
        mealDate: now.mealDate,
        mealTime: now.mealTime,
        mealType: _captureType,
        category: result?.category ?? '한식',
        items: result?.items ?? [MealItem(id: newId(), name: '', portion: '', calories: 0, description: '')],
        servingOptions: result?.servingOptions ??
            [
              [1],
              [2, 3],
            ],
        servingIndex: 0,
        macroFeedback: result?.macroFeedback ?? '',
        foodStory: result?.foodStory ?? '',
        imagePath: image,
        recordedLabel: recordedLabel(now.mealDate, now.mealTime, _captureType),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  void _edit(MealRecord meal) {
    setState(() {
      _backTab = _tab;
      _analysisNotice = null;
      _draft = meal.copy();
      _imagePath = meal.imagePath;
    });
  }

  void _leaveOverlay() {
    if (_busy) return;
    setState(() {
      _draft = null;
      _imagePath = null;
      _tab = _backTab;
    });
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !hasValidItem(draft)) return;
    draft.items = draft.items
        .map((item) => item.copy()
          ..name = item.name.trim()
          ..portion = item.portion.trim()
          ..description = item.description.trim())
        .where((item) => item.name.isNotEmpty && item.calories > 0)
        .toList();
    draft.macroFeedback = draft.macroFeedback.trim();
    draft.foodStory = draft.foodStory.trim();
    await widget.store.save(draft);
    if (!mounted) return;
    setState(() {
      _draft = null;
      _imagePath = null;
      _tab = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이 기기에 저장했어요')));
  }

  Future<void> _askDelete(MealRecord meal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 지우기'),
        content: Text('${mealTitle(meal)} 기록을 지울까요? 이 기기에서만 삭제돼요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('지우기')),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.delete(meal.id);
    if (!mounted) return;
    if (_draft?.id == meal.id) {
      setState(() {
        _draft = null;
        _imagePath = null;
      });
    }
  }

  Future<void> _askWipe() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 지우기'),
        content: const Text('이 기기의 식사 기록을 모두 지울까요? 서버에는 올라간 내용이 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('지우기')),
        ],
      ),
    );
    if (ok == true) await widget.store.clear();
  }
}
