import { useEffect, useState } from 'react';
import type { MealRecord } from '../types';
import { eatenCalories, REFERENCES, type CompareKey } from '../lib/calories';
import { formatKoreanDate, seoulStamp } from '../lib/time';
import { MealCard } from '../components/MealCard';

interface Props {
  meals: MealRecord[];
  loaded: boolean;
  onOpen: (meal: MealRecord) => void;
  onDelete: (meal: MealRecord) => void;
}

const KEYS = Object.keys(REFERENCES) as CompareKey[];

export function TodayPage({ meals, loaded, onOpen, onDelete }: Props) {
  const today = seoulStamp().mealDate;
  const todays = meals
    .filter((meal) => meal.mealDate === today)
    .sort((a, b) => a.mealTime.localeCompare(b.mealTime));
  const total = todays.reduce((sum, meal) => sum + eatenCalories(meal), 0);
  const hero = [...todays].reverse().find((meal) => meal.imageDataUrl);
  const [compare, setCompare] = useState<CompareKey>(() => {
    const saved = localStorage.getItem('whatkcal-compare');
    if (saved === '남성' || saved === '여성' || saved === '아이' || saved === '노인') return saved;
    return '여성';
  });

  useEffect(() => {
    localStorage.setItem('whatkcal-compare', compare);
  }, [compare]);

  const ref = REFERENCES[compare];
  const ratio = ref.kcal ? Math.min(total / ref.kcal, 1) : 0;
  const diff = ref.kcal - total;
  let compareCopy = '오늘 기록을 시작하면 막대가 채워져요.';
  if (total > 0 && Math.abs(diff) <= 50) compareCopy = `${ref.label} 참고치와 비슷해요.`;
  else if (total > 0 && diff > 0) compareCopy = `${ref.label} 참고치까지 ${diff.toLocaleString('ko-KR')}kcal 남았어요.`;
  else if (total > 0) compareCopy = `${ref.label} 참고치보다 ${Math.abs(diff).toLocaleString('ko-KR')}kcal 더 기록됐어요.`;

  return (
    <div className="page">
      <section className={hero ? 'hero' : 'hero plain'}>
        {hero && <img className="hero-bg" src={hero.imageDataUrl} alt="" />}
        <div className="hero-shade" />
        <div className="hero-copy">
          <p className="hero-kicker">{formatKoreanDate(today)}</p>
          <p className="hero-kcal">
            {total.toLocaleString('ko-KR')}
            <small>kcal</small>
          </p>
          <p className="hero-sub">{todays.length ? `오늘 ${todays.length}끼를 남겼어요` : '오늘의 첫 식사를 남겨 보세요'}</p>
        </div>
      </section>

      <section className="card">
        <h2>참고치와 비교</h2>
        <div className="compare-row">
          {KEYS.map((key) => (
            <button key={key} type="button" className={key === compare ? 'compare-btn on' : 'compare-btn'} onClick={() => setCompare(key)}>
              {key}
            </button>
          ))}
        </div>
        <div className="meter" aria-hidden="true">
          <span className={total > ref.kcal ? 'over' : ''} style={{ width: `${total ? Math.max(ratio * 100, 6) : 0}%` }} />
        </div>
        <p className="compare-copy">{compareCopy}</p>
        <p className="fine">
          {ref.label} {ref.kcal.toLocaleString('ko-KR')}kcal · {ref.note}
        </p>
      </section>

      {!loaded && <p className="fine">기록을 불러오고 있어요.</p>}
      {loaded && todays.length === 0 && (
        <div className="msg">
          <span className="avatar">왓</span>
          <div className="bubble">오늘 식사는 아직 없어요. 가운데 카메라로 사진을 올려 주세요.</div>
        </div>
      )}
      {todays.map((meal) => (
        <MealCard key={meal.id} meal={meal} onOpen={onOpen} onDelete={onDelete} />
      ))}
      <p className="fine">칼로리는 추정치예요. 진료나 식단 처방을 대신하지 않아요.</p>
    </div>
  );
}
