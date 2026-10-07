import type { Category, MealItem, MealRecord, MealType } from '../types';
import { buildRecordedLabel, detectMealType, seoulStamp } from './time';

export function uid(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function emptyItem(): MealItem {
  return { id: uid(), name: '', portion: '', calories: 0, description: '' };
}

export function mealTitle(meal: Pick<MealRecord, 'items'>): string {
  const names = meal.items.map((item) => item.name.trim()).filter(Boolean);
  return names.length ? names.join(', ') : '이 식사';
}

export function hasValidItem(meal: Pick<MealRecord, 'items'>): boolean {
  return meal.items.some((item) => item.name.trim() && Number(item.calories) > 0);
}

export function createPreviewMeal(imageDataUrl: string, mealType?: MealType): MealRecord {
  const now = seoulStamp();
  const type = mealType ?? detectMealType(now.mealTime);
  return {
    id: uid(),
    mealDate: now.mealDate,
    mealTime: now.mealTime,
    mealType: type,
    category: '한식',
    items: [emptyItem()],
    servingOptions: [[1], [2, 3]],
    servingIndex: 0,
    macroFeedback: '음식 이름과 칼로리를 입력하면 탄단지 균형을 짧게 정리해 드려요.',
    foodStory: '인식 엔진을 연결하면 음식 유래가 이 자리에 채워져요. 지금은 직접 고르거나 입력할 수 있어요.',
    imageDataUrl,
    recordedLabel: buildRecordedLabel(now.mealDate, now.mealTime, type),
    source: 'preview',
    isSynced: 0,
    updatedAt: Date.now(),
  };
}

export function withMealType(meal: MealRecord, mealType: MealType): MealRecord {
  return {
    ...meal,
    mealType,
    recordedLabel: buildRecordedLabel(meal.mealDate, meal.mealTime, mealType),
  };
}

export function withCategory(meal: MealRecord, category: Category): MealRecord {
  return { ...meal, category };
}
