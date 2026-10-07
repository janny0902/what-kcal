import { useEffect, useState } from 'react';
import { MEAL_TYPES, type MealType } from '../types';
import { buildRecordedLabel, detectMealType, seoulStamp } from '../lib/time';

interface Props {
  imageDataUrl: string;
  mealType: MealType;
  onMealType: (mealType: MealType) => void;
  onRetake: () => void;
}

export function CapturePage({ imageDataUrl, mealType, onMealType, onRetake }: Props) {
  const [now, setNow] = useState(() => seoulStamp());

  useEffect(() => {
    const id = window.setInterval(() => setNow(seoulStamp()), 1000);
    return () => window.clearInterval(id);
  }, []);

  return (
    <div className="page">
      <p className="date-chip">{buildRecordedLabel(now.mealDate, now.mealTime, mealType)}</p>
      <div className="preview-frame">
        <img src={imageDataUrl} alt="선택한 식단 사진" />
      </div>
      <section className="card stack">
        <h2>식사</h2>
        <p className="fine">지금 시간 기준은 {detectMealType(now.mealTime)}이에요. 다르게 남기려면 눌러 바꾸세요.</p>
        <div className="chips">
          {MEAL_TYPES.map((type) => (
            <button key={type} type="button" className={type === mealType ? 'chip on' : 'chip'} onClick={() => onMealType(type)}>
              {type}
            </button>
          ))}
        </div>
      </section>
      <button type="button" className="text-btn" onClick={onRetake}>
        다른 사진
      </button>
    </div>
  );
}
