export interface AdCreative {
  title: string;
  body: string;
}

export const BANNER_CREATIVES: AdCreative[] = [
  { title: '오늘의 식탁', body: '사진 한 장으로 칼로리를 남겨요.' },
  { title: '무료로 쓰는 기록', body: '계산할 때 짧은 광고가 나와요.' },
  { title: '이 기기에만 보관', body: '로그인 전 기록은 서버에 올라가지 않아요.' },
];

export const INTERSTITIAL_CREATIVES: AdCreative[] = [
  { title: '칼로리를 정리하고 있어요', body: '광고가 끝나면 결과 화면이 열려요.' },
  { title: '인분을 고르면 내 몫만', body: '같이 먹은 음식은 인분으로 나눠 계산해요.' },
  { title: '게스트로 바로 기록', body: '다른 기기 백업이 필요하면 나중에 로그인할 수 있어요.' },
];

/**
 * 전면 광고 길이. 기본은 5~15초.
 * 광고 계정이 연결되기 전에는 하우스 광고를 보여주고,
 * 광고를 못 받으면 null을 반환해 로딩 화면으로 넘어간다.
 */
export function loadInterstitial(): { seconds: number } | null {
  if (sessionStorage.getItem('whatkcal-ad-fail-once') === '1') {
    sessionStorage.removeItem('whatkcal-ad-fail-once');
    return null;
  }
  const forced = sessionStorage.getItem('whatkcal-ad-seconds');
  if (forced) {
    const seconds = Number(forced);
    if (seconds > 0) return { seconds: Math.min(15, Math.round(seconds)) };
  }
  return { seconds: 5 + Math.floor(Math.random() * 11) };
}

export function markNextAdMiss(): void {
  sessionStorage.setItem('whatkcal-ad-fail-once', '1');
}
