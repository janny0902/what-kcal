import type { MealType } from '../types';

export interface SeoulStamp {
  mealDate: string;
  mealTime: string;
}

export function seoulStamp(date = new Date()): SeoulStamp {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Seoul',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(date);
  const pick = (type: Intl.DateTimeFormatPartTypes) => parts.find((part) => part.type === type)?.value ?? '';
  let hour = pick('hour');
  if (hour === '24') hour = '00';
  return {
    mealDate: `${pick('year')}-${pick('month')}-${pick('day')}`,
    mealTime: `${hour.padStart(2, '0')}:${pick('minute')}:${pick('second')}`,
  };
}

export function buildRecordedLabel(mealDate: string, mealTime: string, mealType: MealType): string {
  return `${mealDate} ${mealTime}(KR) ${mealType}`;
}

/** 한국 시간 기준. 아침·아점·점심·점저·저녁·야식. */
export function detectMealType(time: string): MealType {
  const [hour, minute] = time.split(':').map(Number);
  const mins = hour * 60 + minute;
  if (mins >= 5 * 60 && mins < 9 * 60) return '아침';
  if (mins >= 9 * 60 && mins < 11 * 60) return '아점';
  if (mins >= 11 * 60 && mins < 14 * 60 + 30) return '점심';
  if (mins >= 14 * 60 + 30 && mins < 17 * 60) return '점저';
  if (mins >= 17 * 60 && mins < 21 * 60) return '저녁';
  return '야식';
}

export function formatKoreanDate(ymd: string): string {
  const date = new Date(`${ymd}T12:00:00+09:00`);
  const month = Number(ymd.slice(5, 7));
  const day = Number(ymd.slice(8, 10));
  const weekday = new Intl.DateTimeFormat('ko-KR', {
    timeZone: 'Asia/Seoul',
    weekday: 'long',
  }).format(date);
  return `${month}월 ${day}일 ${weekday}`;
}

export function addDays(ymd: string, days: number): string {
  const base = new Date(`${ymd}T12:00:00+09:00`).getTime();
  return seoulStamp(new Date(base + days * 86400000)).mealDate;
}

export function dayOfWeek(ymd: string): number {
  return new Date(`${ymd}T12:00:00+09:00`).getUTCDay();
}

export function weekOf(ymd: string): string[] {
  const start = addDays(ymd, -dayOfWeek(ymd));
  return Array.from({ length: 7 }, (_, index) => addDays(start, index));
}

export function monthCells(year: number, month: number): string[] {
  const first = `${year}-${String(month).padStart(2, '0')}-01`;
  const start = addDays(first, -dayOfWeek(first));
  return Array.from({ length: 42 }, (_, index) => addDays(start, index));
}

export function shiftMonth(year: number, month: number, delta: number): { year: number; month: number } {
  const date = new Date(Date.UTC(year, month - 1 + delta, 1));
  return { year: date.getUTCFullYear(), month: date.getUTCMonth() + 1 };
}
