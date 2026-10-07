import { useMemo, useState } from 'react';
import type { MealRecord } from '../types';
import { eatenCalories } from '../lib/calories';
import { formatKoreanDate, monthCells, seoulStamp, shiftMonth, weekOf } from '../lib/time';
import { MealCard } from '../components/MealCard';

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토'];

interface Props {
  meals: MealRecord[];
  onOpen: (meal: MealRecord) => void;
  onDelete: (meal: MealRecord) => void;
}

export function CalendarPage({ meals, onOpen, onDelete }: Props) {
  const today = seoulStamp().mealDate;
  const [cursor, setCursor] = useState(() => {
    const [year, month] = today.split('-').map(Number);
    return { year, month };
  });
  const [selected, setSelected] = useState(today);
  const cells = monthCells(cursor.year, cursor.month);
  const week = weekOf(selected);

  const byDate = useMemo(() => {
    const map = new Map<string, number>();
    for (const meal of meals) {
      map.set(meal.mealDate, (map.get(meal.mealDate) ?? 0) + eatenCalories(meal));
    }
    return map;
  }, [meals]);

  const weekValues = week.map((ymd) => byDate.get(ymd) ?? 0);
  const weekSum = weekValues.reduce((sum, value) => sum + value, 0);
  const weekMax = Math.max(...weekValues, 0);
  const selectedMeals = meals
    .filter((meal) => meal.mealDate === selected)
    .sort((a, b) => a.mealTime.localeCompare(b.mealTime));

  return (
    <div className="page">
      <section className="card">
        <div className="card-head">
          <h2>주간</h2>
          <p>
            {Number(week[0].slice(5, 7))}월 {Number(week[0].slice(8, 10))}일 – {Number(week[6].slice(5, 7))}월{' '}
            {Number(week[6].slice(8, 10))}일
          </p>
        </div>
        <div className="week-bars">
          {week.map((ymd, index) => {
            const value = weekValues[index];
            const pct = weekMax ? Math.round((value / weekMax) * 100) : 0;
            return (
              <button key={ymd} type="button" className={ymd === selected ? 'col on' : 'col'} onClick={() => setSelected(ymd)}>
                <span className="track">
                  <span
                    className={value ? 'fill' : 'fill empty'}
                    style={{ height: value ? `${Math.max(pct, 12)}%` : 4 }}
                  />
                </span>
                <span className="dow">{WEEKDAYS[index]}</span>
              </button>
            );
          })}
        </div>
        <div className="stat-row">
          <p>
            <span>누적</span>
            <strong>{weekSum.toLocaleString('ko-KR')}kcal</strong>
          </p>
          <p>
            <span>7일 평균</span>
            <strong>{Math.round(weekSum / 7).toLocaleString('ko-KR')}kcal</strong>
          </p>
        </div>
      </section>

      <section className="card">
        <div className="card-head">
          <button type="button" className="nav-btn" onClick={() => setCursor(shiftMonth(cursor.year, cursor.month, -1))} aria-label="이전 달">
            ‹
          </button>
          <h2>
            {cursor.year}년 {cursor.month}월
          </h2>
          <button type="button" className="nav-btn" onClick={() => setCursor(shiftMonth(cursor.year, cursor.month, 1))} aria-label="다음 달">
            ›
          </button>
        </div>
        <div className="cal-grid heads">
          {WEEKDAYS.map((label) => (
            <span key={label}>{label}</span>
          ))}
        </div>
        <div className="cal-grid">
          {cells.map((ymd) => {
            const inMonth = Number(ymd.slice(0, 4)) === cursor.year && Number(ymd.slice(5, 7)) === cursor.month;
            const kcal = byDate.get(ymd) ?? 0;
            const className = [
              'cal-cell',
              inMonth ? '' : 'out',
              ymd === selected ? 'on' : '',
              ymd === today ? 'today' : '',
            ]
              .filter(Boolean)
              .join(' ');
            return (
              <button key={ymd} type="button" className={className} onClick={() => setSelected(ymd)}>
                <span>{Number(ymd.slice(8, 10))}</span>
                {kcal > 0 && inMonth && <small>{kcal.toLocaleString('ko-KR')}</small>}
              </button>
            );
          })}
        </div>
      </section>

      <p className="date-chip">{formatKoreanDate(selected)}</p>
      {selectedMeals.length === 0 && (
        <div className="msg">
          <span className="avatar">왓</span>
          <div className="bubble">이 날은 아직 기록이 없어요.</div>
        </div>
      )}
      {selectedMeals.map((meal) => (
        <MealCard key={meal.id} meal={meal} onOpen={onOpen} onDelete={onDelete} />
      ))}
    </div>
  );
}
