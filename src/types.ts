export const MEAL_TYPES = ['아침', '아점', '점심', '점저', '저녁', '야식'] as const;
export type MealType = (typeof MEAL_TYPES)[number];

export const CATEGORIES = [
  '한식',
  '양식',
  '중식',
  '일식',
  '분식',
  '구내식당',
  '패스트푸드',
  '디저트/카페',
] as const;
export type Category = (typeof CATEGORIES)[number];

export interface MealItem {
  id: string;
  name: string;
  portion: string;
  calories: number;
  description: string;
}

export interface MealRecord {
  id: string;
  mealDate: string;
  mealTime: string;
  mealType: MealType;
  category: Category;
  items: MealItem[];
  servingOptions: number[][];
  servingIndex: number;
  macroFeedback: string;
  foodStory: string;
  imageDataUrl: string;
  recordedLabel: string;
  source: 'preview' | 'api';
  isSynced: 0 | 1;
  updatedAt: number;
}
