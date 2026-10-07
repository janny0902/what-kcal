import { CATEGORIES, MEAL_TYPES, type Category, type MealItem, type MealRecord, type MealType } from '../types';
import { baseCalories, eatenCalories, servingLabel } from '../lib/calories';
import { applyPreset, PRESETS } from '../lib/presets';
import { emptyItem, withCategory, withMealType } from '../lib/meals';

interface Props {
  draft: MealRecord;
  saved: boolean;
  onChange: (draft: MealRecord) => void;
  onDelete: () => void;
}

export function ResultPage({ draft, saved, onChange, onDelete }: Props) {
  const base = Math.round(baseCalories(draft.items));
  const eaten = eatenCalories(draft);
  const shared = (draft.servingOptions[draft.servingIndex] ?? [1]).length > 1 || (draft.servingOptions[draft.servingIndex]?.[0] ?? 1) > 1;

  function patchItem(id: string, patch: Partial<MealItem>) {
    onChange({
      ...draft,
      items: draft.items.map((item) => (item.id === id ? { ...item, ...patch } : item)),
    });
  }

  return (
    <div className="page">
      <p className="date-chip">{draft.recordedLabel}</p>
      {draft.source === 'preview' && (
        <div className="msg">
          <span className="avatar">왓</span>
          <div className="bubble">사진 인식 엔진 연결 전이에요. 음식을 고르거나 직접 입력한 뒤 저장해 주세요.</div>
        </div>
      )}

      <div className="preview-frame">
        <img src={draft.imageDataUrl} alt="분석한 식단 사진" />
      </div>

      <section className="card stack">
        <div className="split">
          <label>
            식사
            <select
              value={draft.mealType}
              onChange={(event) => onChange(withMealType(draft, event.target.value as MealType))}
            >
              {MEAL_TYPES.map((type) => (
                <option key={type}>{type}</option>
              ))}
            </select>
          </label>
          <label>
            분류
            <select
              value={draft.category}
              onChange={(event) => onChange(withCategory(draft, event.target.value as Category))}
            >
              {CATEGORIES.map((category) => (
                <option key={category}>{category}</option>
              ))}
            </select>
          </label>
        </div>
      </section>

      <section className="card stack">
        <h2>빠른 입력</h2>
        <div className="chips scroll-x">
          {PRESETS.map((preset) => (
            <button key={preset.name} type="button" className="chip" onClick={() => onChange(applyPreset(draft, preset))}>
              {preset.name}
            </button>
          ))}
        </div>
      </section>

      <section className="card stack">
        <h2>음식</h2>
        {draft.items.map((item, index) => (
          <div key={item.id} className="item-edit">
            <label>
              이름
              <input
                value={item.name}
                placeholder="음식 이름"
                onChange={(event) => patchItem(item.id, { name: event.target.value })}
              />
            </label>
            <label>
              칼로리
              <input
                inputMode="numeric"
                type="number"
                min={0}
                value={item.calories || ''}
                placeholder="0"
                onChange={(event) => patchItem(item.id, { calories: Number(event.target.value) || 0 })}
              />
            </label>
            <label className="wide">
              분량
              <input
                value={item.portion}
                placeholder="1공기, 반 접시"
                onChange={(event) => patchItem(item.id, { portion: event.target.value })}
              />
            </label>
            <label className="wide">
              설명
              <input
                value={item.description}
                placeholder="사진 속 특징"
                onChange={(event) => patchItem(item.id, { description: event.target.value })}
              />
            </label>
            {draft.items.length > 1 && (
              <button
                type="button"
                className="linkish"
                onClick={() => onChange({ ...draft, items: draft.items.filter((row) => row.id !== item.id) })}
              >
                {index + 1}번 항목 빼기
              </button>
            )}
          </div>
        ))}
        <button type="button" className="ghost" onClick={() => onChange({ ...draft, items: [...draft.items, emptyItem()] })}>
          음식 추가
        </button>
      </section>

      <section className="card stack">
        <h2>인분</h2>
        <p className="fine">사진에 담긴 음식을 몇 명이 나눴는지 고르면, 내 칼로리만 계산해요.</p>
        <div className="chips">
          {draft.servingOptions.map((option, index) => (
            <button
              key={`${index}-${option.join('-')}`}
              type="button"
              className={index === draft.servingIndex ? 'chip on' : 'chip'}
              onClick={() => onChange({ ...draft, servingIndex: index })}
            >
              {servingLabel(option)}
            </button>
          ))}
        </div>
      </section>

      <div className="total-bubble">
        <span>내 섭취</span>
        <strong>{eaten.toLocaleString('ko-KR')}</strong>
        <em>kcal</em>
        {shared && base !== eaten && <p>사진 전체 {base.toLocaleString('ko-KR')}kcal</p>}
      </div>

      <div className="msg">
        <span className="avatar">왓</span>
        <label className="bubble">
          <span className="who">탄단지</span>
          <textarea
            value={draft.macroFeedback}
            rows={3}
            onChange={(event) => onChange({ ...draft, macroFeedback: event.target.value })}
          />
        </label>
      </div>
      <div className="msg">
        <span className="avatar">왓</span>
        <label className="bubble">
          <span className="who">음식 이야기</span>
          <textarea value={draft.foodStory} rows={4} onChange={(event) => onChange({ ...draft, foodStory: event.target.value })} />
        </label>
      </div>

      {saved && (
        <button type="button" className="danger-text" onClick={onDelete}>
          이 기록 지우기
        </button>
      )}
    </div>
  );
}
