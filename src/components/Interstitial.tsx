import { useMemo } from 'react';
import { INTERSTITIAL_CREATIVES } from '../lib/ads';

interface Props {
  mode: 'ad' | 'fallback';
  left?: number;
  total?: number;
}

export function Interstitial({ mode, left = 0, total = 5 }: Props) {
  const creative = useMemo(
    () => INTERSTITIAL_CREATIVES[Math.floor(Math.random() * INTERSTITIAL_CREATIVES.length)],
    [],
  );

  if (mode === 'fallback') {
    return (
      <div className="interstitial" role="status">
        <div className="ad-card">
          <span className="banner-badge">안내</span>
          <h2>광고를 불러오지 못했어요</h2>
          <p>분석을 그대로 이어갈게요.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="interstitial" role="dialog" aria-modal="true" aria-label="광고">
      <div className="ad-progress" aria-hidden="true">
        <span key={total} style={{ animationDuration: `${total}s` }} />
      </div>
      <div className="ad-card">
        <span className="banner-badge">광고</span>
        <p className="count">{left}</p>
        <h2>{creative.title}</h2>
        <p>{creative.body}</p>
        <p className="fine light">약 {total}초 광고 뒤 결과가 열려요.</p>
      </div>
    </div>
  );
}
