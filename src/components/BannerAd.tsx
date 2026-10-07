import { useEffect, useState } from 'react';
import { BANNER_CREATIVES } from '../lib/ads';

export function BannerAd() {
  const [index, setIndex] = useState(0);
  const client = import.meta.env.VITE_ADSENSE_CLIENT;
  const slot = import.meta.env.VITE_ADSENSE_SLOT;

  useEffect(() => {
    if (client) return;
    const id = window.setInterval(() => {
      setIndex((current) => (current + 1) % BANNER_CREATIVES.length);
    }, 8000);
    return () => window.clearInterval(id);
  }, [client]);

  if (client && slot) {
    return (
      <aside className="banner" aria-label="광고">
        <span className="banner-badge">광고</span>
        <ins
          className="adsbygoogle"
          style={{ display: 'block' }}
          data-ad-client={client}
          data-ad-slot={slot}
          data-ad-format="horizontal"
        />
      </aside>
    );
  }

  const creative = BANNER_CREATIVES[index];
  return (
    <aside className="banner" aria-label="광고">
      <span className="banner-badge">광고</span>
      <div>
        <strong>{creative.title}</strong>
        <p>{creative.body}</p>
      </div>
    </aside>
  );
}
