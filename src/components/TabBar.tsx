import { IconCalendar, IconCamera, IconHome, IconList, IconUser } from './Icons';

export type TabId = 'today' | 'calendar' | 'archive' | 'settings';

interface Props {
  tab: TabId;
  onTab: (tab: TabId) => void;
  onCamera: () => void;
}

export function TabBar({ tab, onTab, onCamera }: Props) {
  return (
    <nav className="tabbar" aria-label="주요 메뉴">
      <button type="button" className={tab === 'today' ? 'tab on' : 'tab'} onClick={() => onTab('today')}>
        <IconHome />
        오늘
      </button>
      <button type="button" className={tab === 'calendar' ? 'tab on' : 'tab'} onClick={() => onTab('calendar')}>
        <IconCalendar />
        달력
      </button>
      <button type="button" className="cam" onClick={onCamera} aria-label="식단 사진 올리기">
        <IconCamera />
      </button>
      <button type="button" className={tab === 'archive' ? 'tab on' : 'tab'} onClick={() => onTab('archive')}>
        <IconList />
        기록
      </button>
      <button type="button" className={tab === 'settings' ? 'tab on' : 'tab'} onClick={() => onTab('settings')}>
        <IconUser />
        설정
      </button>
    </nav>
  );
}
