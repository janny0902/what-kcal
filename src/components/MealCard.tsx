import type { MealRecord } from '../types';
import { eatenCalories } from '../lib/calories';
import { mealTitle } from '../lib/meals';

interface Props {
  meal: MealRecord;
  onOpen: (meal: MealRecord) => void;
  onDelete: (meal: MealRecord) => void;
}

export function MealCard({ meal, onOpen, onDelete }: Props) {
  const title = mealTitle(meal);
  const kcal = eatenCalories(meal);
  return (
    <article className="meal">
      <button type="button" className="meal-hit" onClick={() => onOpen(meal)} aria-label={`${title} 기록 열기`}>
        <img src={meal.imageDataUrl} alt="" />
        <div className="meal-copy">
          <strong>{title}</strong>
          <span className="pill">{meal.mealType}</span>
          <p>{meal.category}</p>
        </div>
        <div className="kcal">
          <strong>{kcal.toLocaleString('ko-KR')}</strong>
          <small>kcal</small>
        </div>
      </button>
      <button type="button" className="linkish" onClick={() => onDelete(meal)}>
        지우기
      </button>
    </article>
  );
}
