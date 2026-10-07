import type { MealRecord } from '../types';

export type CompareKey = '남성' | '여성' | '아이' | '노인';

export const REFERENCES: Record<CompareKey, { label: string; kcal: number; note: string }> = {
  남성: { label: '성인 남성', kcal: 2500, note: '활동량에 따라 달라지는 하루 참고치예요.' },
  여성: { label: '성인 여성', kcal: 2000, note: '활동량에 따라 달라지는 하루 참고치예요.' },
  아이: { label: '아이', kcal: 1700, note: '학령기 전후를 넓게 잡은 참고치예요.' },
  노인: { label: '노인', kcal: 1800, note: '65세 전후를 넓게 잡은 참고치예요.' },
};

export function servingLabel(option: number[]): string {
  if (option.length <= 1) return `${option[0] ?? 1}인분`;
  return `${Math.min(...option)}~${Math.max(...option)}인분`;
}

export function servingDivisor(option: number[]): number {
  if (!option.length) return 1;
  return option.reduce((sum, value) => sum + value, 0) / option.length;
}

export function baseCalories(items: { calories: number }[]): number {
  return items.reduce((sum, item) => sum + (Number(item.calories) || 0), 0);
}

export function eatenCalories(meal: Pick<MealRecord, 'items' | 'servingOptions' | 'servingIndex'>): number {
  const base = baseCalories(meal.items);
  const option = meal.servingOptions[meal.servingIndex] ?? [1];
  const divisor = servingDivisor(option);
  if (!divisor) return Math.round(base);
  return Math.max(0, Math.round(base / divisor));
}
