import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.draft, required this.onChanged});

  final MealRecord draft;
  final ValueChanged<MealRecord> onChanged;

  @override
  Widget build(BuildContext context) {
    final eaten = eatenCalories(draft);
    final base = baseCalories(draft);
    final option = draft.servingOptions[draft.servingIndex];
    final shared = servingDivisor(option) != 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Center(child: Text(draft.recordedLabel, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
        const SizedBox(height: 12),
        const ChatBubble(child: Text('음식을 고르거나 직접 입력한 뒤 이 기기에 저장해 주세요.')),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.file(File(draft.imagePath), height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Row(
            children: [
              Expanded(child: _drop('식사', draft.mealType, mealTypes, (value) {
                draft.mealType = value;
                draft.recordedLabel = recordedLabel(draft.mealDate, draft.mealTime, value);
                onChanged(draft);
              })),
              const SizedBox(width: 8),
              Expanded(child: _drop('분류', draft.category, categories, (value) {
                draft.category = value;
                onChanged(draft);
              })),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('빠른 입력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in presets)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(preset.name),
                          backgroundColor: AppColors.mintSoft,
                          side: BorderSide.none,
                          onPressed: () {
                            draft.category = preset.category;
                            draft.macroFeedback = preset.macro;
                            draft.foodStory = preset.story;
                            draft.formEpoch += 1;
                            draft.items = [
                              MealItem(id: newId(), name: preset.name, portion: preset.portion, calories: preset.calories, description: preset.description),
                            ];
                            onChanged(draft);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('음식', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final item in draft.items) ...[
                Row(
                  children: [
                    Expanded(child: _field('이름', item.name, (value) {
                      item.name = value;
                      onChanged(draft);
                    }, fieldKey: '${item.id}-name')),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 96,
                      child: _field('칼로리', item.calories == 0 ? '' : '${item.calories}', (value) {
                        item.calories = int.tryParse(value) ?? 0;
                        onChanged(draft);
                      }, number: true, fieldKey: '${item.id}-kcal'),
                    ),
                  ],
                ),
                _field('분량', item.portion, (value) {
                  item.portion = value;
                  onChanged(draft);
                }, fieldKey: '${item.id}-portion'),
                _field('설명', item.description, (value) {
                  item.description = value;
                  onChanged(draft);
                }, fieldKey: '${item.id}-desc'),
                if (draft.items.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        draft.items.remove(item);
                        onChanged(draft);
                      },
                      child: const Text('항목 빼기', style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                const Divider(color: AppColors.line),
              ],
              OutlinedButton(
                onPressed: () {
                  draft.items.add(MealItem(id: newId(), name: '', portion: '', calories: 0, description: ''));
                  onChanged(draft);
                },
                child: const Text('음식 추가'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('인분', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('사진에 담긴 음식을 몇 명이 나눴는지 고르면, 내 칼로리만 계산해요.', style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i < draft.servingOptions.length; i++)
                    ChoiceChip(
                      label: Text(servingText(draft.servingOptions[i])),
                      selected: draft.servingIndex == i,
                      onSelected: (_) {
                        draft.servingIndex = i;
                        onChanged(draft);
                      },
                      selectedColor: AppColors.mint,
                      backgroundColor: AppColors.mintSoft,
                      labelStyle: TextStyle(color: draft.servingIndex == i ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700),
                      showCheckmark: false,
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(minWidth: 180),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3ADCCB), Color(0xFF13C3B3)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(22), topRight: Radius.circular(6), bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('내 섭취', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${comma(eaten)} kcal', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                if (shared && base != eaten) Text('사진 전체 ${comma(base)}kcal', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ChatBubble(child: _area('탄단지', draft.macroFeedback, (value) {
          draft.macroFeedback = value;
          onChanged(draft);
        }, fieldKey: '${draft.id}-macro-${draft.formEpoch}')),
        const SizedBox(height: 12),
        ChatBubble(child: _area('음식 이야기', draft.foodStory, (value) {
          draft.foodStory = value;
          onChanged(draft);
        }, fieldKey: '${draft.id}-story-${draft.formEpoch}')),
      ],
    );
  }

  Widget _drop(String label, String value, List<String> options, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700)),
        DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: [for (final option in options) DropdownMenuItem(value: option, child: Text(option))],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged, {bool number = false, String? fieldKey}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: fieldKey == null ? null : ValueKey(fieldKey),
        initialValue: value,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FBFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _area(String label, String value, ValueChanged<String> onChanged, {required String fieldKey}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mintDeep, fontSize: 12, fontWeight: FontWeight.w700)),
        TextFormField(
          key: ValueKey(fieldKey),
          initialValue: value,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
