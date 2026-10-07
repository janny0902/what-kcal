import { useEffect, useRef, useState, type ChangeEvent } from 'react';
import type { MealRecord, MealType } from './types';
import { clearMeals, deleteMeal, getAllMeals, putMeal } from './lib/db';
import { compressImage } from './lib/image';
import { createPreviewMeal, hasValidItem, mealTitle } from './lib/meals';
import { loadInterstitial, markNextAdMiss } from './lib/ads';
import { detectMealType, formatKoreanDate, seoulStamp } from './lib/time';
import { BannerAd } from './components/BannerAd';
import { Chevron, Heart } from './components/Icons';
import { Interstitial } from './components/Interstitial';
import { Sheet } from './components/Sheet';
import { TabBar, type TabId } from './components/TabBar';
import { TodayPage } from './pages/TodayPage';
import { CalendarPage } from './pages/CalendarPage';
import { ArchivePage } from './pages/ArchivePage';
import { SettingsPage } from './pages/SettingsPage';
import { CapturePage } from './pages/CapturePage';
import { ResultPage } from './pages/ResultPage';

type Screen = TabId | 'capture' | 'result';
type Gate = { kind: 'ad'; total: number; left: number } | { kind: 'fallback' } | null;

function isMain(screen: Screen): screen is TabId {
  return screen === 'today' || screen === 'calendar' || screen === 'archive' || screen === 'settings';
}

export default function App() {
  const [screen, setScreen] = useState<Screen>('today');
  const [backScreen, setBackScreen] = useState<TabId>('today');
  const [meals, setMeals] = useState<MealRecord[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [dbError, setDbError] = useState('');
  const [draft, setDraft] = useState<MealRecord | null>(null);
  const [pendingImage, setPendingImage] = useState('');
  const [captureType, setCaptureType] = useState<MealType>('점심');
  const [gate, setGate] = useState<Gate>(null);
  const [picker, setPicker] = useState(false);
  const [hello, setHello] = useState(false);
  const [loginOpen, setLoginOpen] = useState(false);
  const [confirm, setConfirm] = useState<null | { text: string; run: () => void }>(null);
  const [toast, setToast] = useState('');
  const cameraRef = useRef<HTMLInputElement>(null);
  const albumRef = useRef<HTMLInputElement>(null);
  const failTimer = useRef<number | null>(null);
  const toastTimer = useRef<number | null>(null);

  useEffect(() => {
    let live = true;
    getAllMeals()
      .then((rows) => {
        if (live) setMeals(rows);
      })
      .catch(() => {
        if (live) setDbError('이 브라우저에서는 기록을 저장할 수 없어요.');
      })
      .finally(() => {
        if (live) setLoaded(true);
      });
    if (!localStorage.getItem('whatkcal-hello-v1')) setHello(true);
    return () => {
      live = false;
    };
  }, []);

  useEffect(() => {
    if (!gate || gate.kind !== 'ad') return;
    const id = window.setTimeout(() => {
      if (gate.left <= 1) {
        setScreen('result');
        setGate(null);
        return;
      }
      setGate({ kind: 'ad', total: gate.total, left: gate.left - 1 });
    }, 1000);
    return () => window.clearTimeout(id);
  }, [gate]);

  useEffect(() => {
    if (gate?.kind === 'fallback' && draft) {
      setScreen('result');
      setGate(null);
    }
  }, [gate, draft]);

  useEffect(() => {
    return () => {
      if (failTimer.current) window.clearTimeout(failTimer.current);
      if (toastTimer.current) window.clearTimeout(toastTimer.current);
    };
  }, []);

  function showToast(text: string) {
    if (toastTimer.current) window.clearTimeout(toastTimer.current);
    setToast(text);
    toastTimer.current = window.setTimeout(() => setToast(''), 1800);
  }

  function acknowledgeHello() {
    localStorage.setItem('whatkcal-hello-v1', '1');
    setHello(false);
  }

  function openPicker() {
    if (isMain(screen)) setBackScreen(screen);
    setPicker(true);
  }

  async function onFile(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    setPicker(false);
    try {
      const image = await compressImage(file);
      setPendingImage(image);
      setCaptureType(detectMealType(seoulStamp().mealTime));
      if (isMain(screen)) setBackScreen(screen);
      setScreen('capture');
    } catch {
      showToast('사진을 읽지 못했어요.');
    }
  }

  function beginAnalyze() {
    if (!pendingImage || gate) return;
    const next = createPreviewMeal(pendingImage, captureType);
    const ad = loadInterstitial();
    if (!ad) {
      setDraft(null);
      setGate({ kind: 'fallback' });
      if (failTimer.current) window.clearTimeout(failTimer.current);
      failTimer.current = window.setTimeout(() => setDraft(next), 900);
      return;
    }
    setDraft(next);
    setGate({ kind: 'ad', total: ad.seconds, left: ad.seconds });
  }

  function editMeal(meal: MealRecord) {
    if (isMain(screen)) setBackScreen(screen);
    setDraft(meal);
    setScreen('result');
  }

  function goBack() {
    const target = isMain(backScreen) ? backScreen : 'today';
    if (screen === 'capture') setPendingImage('');
    if (screen === 'result') setDraft(null);
    setScreen(target);
  }

  async function saveDraft() {
    if (!draft || !hasValidItem(draft)) return;
    const next: MealRecord = {
      ...draft,
      items: draft.items
        .map((item) => ({
          ...item,
          name: item.name.trim(),
          portion: item.portion.trim(),
          description: item.description.trim(),
          calories: Math.round(Number(item.calories) || 0),
        }))
        .filter((item) => item.name && item.calories > 0),
      macroFeedback: draft.macroFeedback.trim(),
      foodStory: draft.foodStory.trim(),
      isSynced: 0,
      updatedAt: Date.now(),
    };
    try {
      await putMeal(next);
    } catch {
      showToast('저장하지 못했어요. 저장 공간을 확인해 주세요.');
      return;
    }
    setMeals((list) =>
      [next, ...list.filter((meal) => meal.id !== next.id)].sort((a, b) =>
        (b.mealDate + b.mealTime).localeCompare(a.mealDate + a.mealTime),
      ),
    );
    setDraft(null);
    setPendingImage('');
    setScreen('today');
    showToast('이 기기에 저장했어요');
  }

  async function remove(id: string) {
    try {
      await deleteMeal(id);
    } catch {
      showToast('지우지 못했어요.');
      return;
    }
    setMeals((list) => list.filter((meal) => meal.id !== id));
    if (draft?.id === id) {
      setDraft(null);
      setScreen(isMain(backScreen) ? backScreen : 'today');
    }
    showToast('기록을 지웠어요');
  }

  async function wipe() {
    try {
      await clearMeals();
    } catch {
      showToast('기록을 지우지 못했어요.');
      return;
    }
    setMeals([]);
    setDraft(null);
    showToast('이 기기의 기록을 지웠어요');
  }

  function askDelete(meal: MealRecord) {
    setConfirm({
      text: `${mealTitle(meal)} 기록을 지울까요? 이 기기에서만 삭제돼요.`,
      run: () => {
        void remove(meal.id);
      },
    });
  }

  const todayLabel = formatKoreanDate(seoulStamp().mealDate);
  const titles: Record<Screen, { title: string; sub?: string }> = {
    today: { title: '왓칼로리', sub: todayLabel },
    calendar: { title: '달력', sub: '주간과 월간' },
    archive: { title: '기록', sub: '이 기기에 남긴 식사' },
    settings: { title: '설정', sub: '게스트' },
    capture: { title: '식단 올리기', sub: '계산 전 식사를 확인해요' },
    result: { title: '분석 결과', sub: '확인하고 이 기기에 저장해요' },
  };
  const heading = titles[screen];
  const showTabs = isMain(screen);
  const saved = Boolean(draft && meals.some((meal) => meal.id === draft.id));

  return (
    <div className="app">
      <header className="header">
        {showTabs ? (
          <span className="logo">
            <Heart />
          </span>
        ) : (
          <button type="button" className="back" onClick={goBack} aria-label="뒤로">
            <Chevron />
          </button>
        )}
        <div>
          <h1>{heading.title}</h1>
          {heading.sub && <p>{heading.sub}</p>}
        </div>
      </header>

      {dbError && <p className="warn">{dbError}</p>}

      <main className="scroll">
        {screen === 'today' && <TodayPage meals={meals} loaded={loaded} onOpen={editMeal} onDelete={askDelete} />}
        {screen === 'calendar' && <CalendarPage meals={meals} onOpen={editMeal} onDelete={askDelete} />}
        {screen === 'archive' && <ArchivePage meals={meals} loaded={loaded} onOpen={editMeal} onDelete={askDelete} />}
        {screen === 'settings' && (
          <SettingsPage
            mealCount={meals.length}
            onWipe={() =>
              setConfirm({
                text: '이 기기의 식사 기록을 모두 지울까요? 서버에는 올라간 내용이 없어요.',
                run: () => {
                  void wipe();
                },
              })
            }
            onLoginInfo={() => setLoginOpen(true)}
            onAdMiss={() => {
              markNextAdMiss();
              showToast('다음 계산은 광고 없이 이어질게요');
            }}
          />
        )}
        {screen === 'capture' && pendingImage && (
          <CapturePage imageDataUrl={pendingImage} mealType={captureType} onMealType={setCaptureType} onRetake={openPicker} />
        )}
        {screen === 'result' && draft && (
          <ResultPage
            draft={draft}
            saved={saved}
            onChange={setDraft}
            onDelete={() => askDelete(draft)}
          />
        )}
      </main>

      {showTabs && <BannerAd />}
      {screen === 'capture' && pendingImage && (
        <footer className="savebar">
          <button type="button" className="primary" onClick={beginAnalyze} disabled={Boolean(gate)}>
            계산하기
          </button>
          <p className="fine">계산이 시작되면 5~15초 광고가 재생돼요.</p>
        </footer>
      )}
      {screen === 'result' && draft && (
        <footer className="savebar">
          <BannerAd />
          <button type="button" className="primary" onClick={() => void saveDraft()} disabled={!hasValidItem(draft)}>
            이 기기에 저장
          </button>
        </footer>
      )}
      {showTabs && (
        <TabBar
          tab={screen}
          onTab={(tab) => {
            setBackScreen(tab);
            setScreen(tab);
          }}
          onCamera={openPicker}
        />
      )}

      {gate?.kind === 'ad' && <Interstitial mode="ad" left={gate.left} total={gate.total} />}
      {gate?.kind === 'fallback' && <Interstitial mode="fallback" />}

      {picker && (
        <Sheet title="식단 사진" onClose={() => setPicker(false)}>
          <p>카메라로 찍거나 앨범에서 고르면, 계산 전에 광고가 나와요.</p>
          <button type="button" className="primary" onClick={() => cameraRef.current?.click()}>
            카메라로 찍기
          </button>
          <button type="button" className="ghost" onClick={() => albumRef.current?.click()}>
            앨범에서 고르기
          </button>
        </Sheet>
      )}

      {hello && (
        <Sheet title="로그인 없이 시작해요" onClose={acknowledgeHello}>
          <p>기록은 이 기기에만 남아요. 로그인하지 않으면 서버에 저장되지 않고, 앱을 지우면 기록도 함께 사라집니다.</p>
          <button type="button" className="primary" onClick={acknowledgeHello}>
            알겠어요
          </button>
        </Sheet>
      )}

      {loginOpen && (
        <Sheet title="백업용 로그인" onClose={() => setLoginOpen(false)}>
          <p>다른 기기에서 기록을 복원하려면 Google 또는 카카오 로그인이 필요해요. 지금은 서버 연동 전이라 게스트로 동작하고, 사진은 이 기기에만 보관됩니다.</p>
          <button type="button" className="ghost" onClick={() => setLoginOpen(false)}>
            Google 로그인은 준비 중
          </button>
          <button type="button" className="ghost" onClick={() => setLoginOpen(false)}>
            카카오 로그인은 준비 중
          </button>
        </Sheet>
      )}

      {confirm && (
        <Sheet title="확인" onClose={() => setConfirm(null)}>
          <p>{confirm.text}</p>
          <button
            type="button"
            className="primary"
            onClick={() => {
              const run = confirm.run;
              setConfirm(null);
              run();
            }}
          >
            지우기
          </button>
          <button type="button" className="ghost" onClick={() => setConfirm(null)}>
            취소
          </button>
        </Sheet>
      )}

      {toast && (
        <div className="toast" role="status">
          {toast}
        </div>
      )}

      <input ref={cameraRef} type="file" accept="image/*" capture="environment" hidden onChange={onFile} />
      <input ref={albumRef} type="file" accept="image/*" hidden onChange={onFile} />
    </div>
  );
}
