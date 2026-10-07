interface Props {
  mealCount: number;
  onWipe: () => void;
  onLoginInfo: () => void;
  onAdMiss: () => void;
}

export function SettingsPage({ mealCount, onWipe, onLoginInfo, onAdMiss }: Props) {
  return (
    <div className="page">
      <section className="card profile">
        <span className="avatar lg">왓</span>
        <div>
          <h2>게스트</h2>
          <p>기록 {mealCount.toLocaleString('ko-KR')}개 · 이 기기에만 보관</p>
        </div>
      </section>

      <section className="card stack">
        <h2>데이터</h2>
        <p>로그인하지 않으면 서버에 기록이 남지 않아요. 앱이나 브라우저 저장소를 지우면 이 기기의 식사 기록도 함께 사라집니다.</p>
        <p>사진은 기기에만 두고, 나중에 백업은 음식 이름과 칼로리 같은 텍스트부터 올릴 예정이에요.</p>
        <button type="button" className="ghost" onClick={onLoginInfo}>
          Google · 카카오 로그인 안내
        </button>
      </section>

      <section className="card stack">
        <h2>광고</h2>
        <p>계산하기를 누르면 5초에서 15초 전면 광고가 나와요. 오늘, 달력, 기록, 설정, 결과 화면 아래에는 배너가 있어요.</p>
        <p>광고를 불러오지 못하면 기다리지 않고 결과로 이어져요.</p>
        <button type="button" className="ghost" onClick={onAdMiss}>
          다음 계산은 광고 없이 보기
        </button>
      </section>

      <section className="card stack">
        <h2>식사 시간</h2>
        <p>한국 시간으로 아침 5시, 아점 9시, 점심 11시, 점저 2시 30분, 저녁 5시, 그 외는 야식으로 나눠요. 결과에서 직접 바꿀 수 있어요.</p>
      </section>

      <button type="button" className="danger-text" onClick={onWipe}>
        이 기기의 기록 모두 지우기
      </button>
    </div>
  );
}
