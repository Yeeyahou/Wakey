# Wakey

<p align="center">
  <img width="200" height="200" alt="image" src="https://github.com/user-attachments/assets/710d2c90-abaf-4650-a508-909a9c7516c1" />
</p>
Wakey는 사용자의 일정, 위치, 날씨, 메모등의 정보를 바탕으로 AI 알람송을 생성하고, 생성된 노래로 알람을 설정할 수 있는 iOS 알람 앱입니다.

## 주요 기능 및 화면

- 홈화면
  <p align="center">
    <img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/043d3ba0-e351-4491-8dfd-ff2b911db2de" />
  </p>

- AI 알람송 생성
  - 알람 날짜, 이름, 목적, 분위기, 메모, 위치, 날씨, 캘린더 정보를 조합해 가사와 노래 제목을 생성합니다.
  - 생성된 제목과 가사를 Suno 요청에 사용해 실제 알람송 오디오를 만듭니다.
  - iOS 로컬 알림용 짧은 오디오 파일도 별도로 생성합니다.
 <p align="center">
    <img width="250" height="500" alt="제목 없는 디자인" src="https://github.com/user-attachments/assets/99634906-3e4d-4b77-9da3-657e6e2fad96" />
 </p>


- 알람 관리
  - 일반 알람과 AI 알람송 알람을 함께 관리합니다.
  - 알람 삭제와 라이브러리 삭제를 분리해, 알람만 지워도 생성된 노래는 유지할 수 있습니다.
  - 반복 요일, 다시 알림, 알람 목적, 알람 음량을 설정할 수 있습니다.
 <p align="center">
    <img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/d93c5f0b-b387-415d-baf8-7e763e6debb4" />
 </p>

- AI 알람송 라이브러리
  - 생성된 AI 알람송을 라이브러리에서 다시 들을 수 있습니다.
  - 저장된 AI 알람송을 일반 알람 사운드 선택 화면에서 선택할 수 있습니다.
  - 라이브러리 카드 스와이프 삭제를 지원합니다.
<p align="center">
<img width="250" height="500" alt="image" src="https://github.com/user-attachments/assets/2b7d2a35-4ba7-452c-9ebb-7937ffa79484" />
</p>
- 알람송 감상 화면
  - AI가 생성한 노래 제목을 표시합니다.
  - 앨범 커버 형태의 주황색 음표 영역을 누르면 가사를 확인할 수 있습니다.
  - 재생바, 재생/일시정지, 알람 음량 조절, 완료 동작을 제공합니다.
 <p align="center">
    <img width="250" height="500" alt="제목 없는 디자인 (1)" src="https://github.com/user-attachments/assets/c968d894-c169-4559-8734-d9fa735b78e8" />
 </p>

- 알람 울림 화면
  - 알림을 누르면 앱 내부의 전체 화면 알람 UI로 이동합니다.
  - 앱이 이미 포그라운드에 있을 때도 알람 화면으로 바로 전환합니다.
  - 검은 배경 위에 주황색 메쉬 그라디언트 느낌의 애니메이션을 표시합니다.
  - 다시 알림과 밀어서 끄기 동작을 제공합니다.
<p align="center">
<img width="250" height="500" alt="ezgif-2b99932f3d7ae8f0" src="https://github.com/user-attachments/assets/faa93265-2ed4-415c-bf3e-41c0ac61911a" />

</p>

- 앱 브랜딩
  - Wakey 앱 아이콘과 런치 로고를 적용했습니다.

 <p align="center">
  <img width="300" height="400" alt="image" src="https://github.com/user-attachments/assets/2697af0c-b08b-4034-a4e7-608b71bfb98e" />
 </p>
## 주요 코드 구조

- `Wakey/Wakey/UIKit/WakeyUIKitControllers.swift`
  - UIKit 기반 주요 화면 컨트롤러가 모여 있는 파일입니다.
  - 홈, 알람 목록, 알람 생성, 사운드 선택, AI 알람송 선택, 생성 로딩, 감상 화면, 라이브러리, 설정, 알람 울림 화면을 담당합니다.
  - `WakeyNotificationRouter`는 푸시 알림 userInfo를 해석해 알람 울림 화면으로 라우팅합니다.
  - `RingingAlarmUIKitViewController`는 알람이 울릴 때 보이는 전체 화면 UI와 다시 알림/밀어서 끄기 동작을 담당합니다.
  - `GeneratingUIKitViewController`는 알람송 생성 중 사용자 친화적인 진행 문구와 로딩 상태를 보여줍니다.
  - `AlarmDetailUIKitViewController`는 생성된 알람송의 재생, 가사 보기, 볼륨 조절, 완료 동작을 처리합니다.

- `Wakey/Wakey/ViewModels/GeneratingViewModel.swift`
  - 알람송 생성 플로우의 중심 ViewModel입니다.
  - 위치, 날씨, 캘린더 정보를 수집하고, 가사 생성, Suno 요청, 오디오 다운로드, 알림용 오디오 생성, 알람 예약까지 순차적으로 처리합니다.
  - `Phase`와 `debugStep`을 통해 생성 단계 상태를 UI에 전달합니다.

- `Wakey/Wakey/Services/LyricsGenerator.swift`
  - AI 가사 및 제목 생성을 담당합니다.
  - 현재 OpenAI 기반 생성 흐름을 사용하며, Gemini 방식으로 되돌리기 쉽도록 기존 구현 흔적을 유지합니다.
  - API 키가 들어갈 수 있는 파일이므로 커밋/공유 시 주의가 필요합니다.

- `Wakey/Wakey/Services/SunoService.swift`
  - Suno 생성 요청, 폴링, 결과 오디오 URL 추출을 담당합니다.
  - 생성 상태가 완료될 때까지 주기적으로 상태를 확인합니다.

- `Wakey/Wakey/Services/AudioFileService.swift`
  - 원본 오디오 저장과 iOS 로컬 알림용 짧은 CAF 오디오 생성을 담당합니다.
  - 알람 음량 설정을 반영한 알림용 오디오 파일을 생성합니다.

- `Wakey/Wakey/Managers/AlarmManager.swift`
  - 알람 목록 저장과 불러오기를 담당합니다.
  - 알람 탭과 라이브러리 탭에서 삭제 상태를 분리해 관리할 수 있도록 모델 상태를 사용합니다.

- `Wakey/Wakey/Managers/NotificationManager.swift`
  - iOS 로컬 알림 권한 요청과 알람 알림 예약을 담당합니다.
  - 알림 payload에 알람 ID를 담아 알림 탭 시 알람 울림 화면으로 연결합니다.

- `Wakey/Wakey/Models/AlarmSong.swift`
  - 알람과 AI 알람송 정보를 함께 표현하는 핵심 모델입니다.
  - 알람 시간, 목적, 분위기, 가사, 원본 오디오, 알림용 오디오, 볼륨, 삭제 상태 등을 저장합니다.

- `Wakey/Wakey/Assets.xcassets`
  - 앱 아이콘, 런치 로고, 색상 에셋을 포함합니다.

## 생성 흐름

1. 사용자가 알람 생성 화면에서 알람 정보와 AI 알람송 옵션을 입력합니다.
2. `GeneratingViewModel`이 위치, 날씨, 캘린더 정보를 필요한 경우 수집합니다.
3. `LyricsGenerator`가 노래 제목과 가사를 한 번의 AI 호출로 생성합니다.
4. `SunoService`가 제목과 가사를 기반으로 알람송 생성을 요청합니다.
5. 생성 완료 후 오디오를 저장하고, `AudioFileService`가 알림용 짧은 오디오를 만듭니다.
6. `NotificationManager`가 로컬 알림을 예약합니다.
7. 생성 결과 화면에서 사용자가 노래를 듣고 알람 음량을 조정할 수 있습니다.
