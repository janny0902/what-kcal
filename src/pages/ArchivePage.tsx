import type { MealRecord } from '../types';
import { formatKoreanDate } from '../lib/time';
import { MealCard } from '../components/MealCard';

interface Props {
  meals: MealRecord[];
  loaded: boolean;
  onOpen: (meal: MealRecord) => void;
  onDelete: (meal: MealRecord) => void;
}

export function ArchivePage({ meals, loaded, onOpen, onDelete }: Props) {
  const groups: { date: string; meals: MealRecord[] }[] = [];
  for (const meal of meals) {
    const last = groups[groups.length - 1];
    if (!last || last.date !== meal.mealDate) groups.push({ date: meal.mealDate, meals: [meal] });
    else last.meals.push(meal);
  }

  return (
    <div className="page">
      {!loaded && <p className="fine">기록을 불러오고 있어요.</p>}
      {loaded && groups.length === 0 && (
        <div className="msg">
          <span className="avatar">왓</span>
          <div className="bubble">아직 남긴 식사가 없어요. 카메라로 첫 기록을 만들어 보세요.</div>
        </div>
      )}
      {groups.map((group) => (
        <section key={group.date} className="day-group">
          <p className="date-chip">{formatKoreanDate(group.date)}</p>
          {group.meals
            .slice()
            .sort((a, b) => a.mealTime.localeCompare(b.mealTime))
            .map((meal) => (
              <MealCard key={meal.id} meal={meal} onOpen={onOpen} onDelete={onDelete} />
            ))}
        </section>
      ))}
    </div>
  );
}
