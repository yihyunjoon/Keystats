# Gizmo Repository Instructions

- 사용자와의 의사소통은 한국어로 합니다.
- 명시적으로 요청받지 않는 한 테스트를 실행하지 않습니다.
- `xcodebuild test`를 포함한 단위 테스트, UI 테스트, 전체 테스트 스위트 실행은 기본적으로 생략합니다.
- 검증이 필요하더라도 먼저 정적 코드 검토를 우선하고, 실행 검증은 사용자가 요청한 경우에만 진행합니다.
- 작업을 마치기 전에는 반드시 빌드 검증을 수행합니다.
- 기본 검증 명령은 `xcodebuild build -project Gizmo.xcodeproj -scheme Gizmo -destination 'platform=macOS'` 입니다.
