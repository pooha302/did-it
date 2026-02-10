---
trigger: always_on
glob:
description: 자동 Flutter Hot Reload 및 Hot Restart 규칙
---

# Flutter Hot Reload/Restart Rules

## Objective
실행 중인 Flutter 애플리케이션에 코드 변경 사항을 자동으로 적용하여 빠른 개발 사이클을 유지합니다.

## Rules
1. **탐지**: 코드 수정을 마칠 때마다 백그라운드에서 실행 중인 `flutter run` 명령이 있는지 확인합니다.
2. **Action Selection**:
   - **Hot Reload (r)**: UI 변경, 스타일 업데이트 및 앱의 전역 상태나 플러그인 초기화에 영향을 주지 않는 대부분의 로직 변경에 사용합니다.
   - **Hot Restart (R)**: 다음과 같은 변경 사항이 포함될 때 사용합니다:
     - `main()` 함수 또는 전역 변수 수정
     - 현재 화면의 `initState` 변경
     - 백그라운드 서비스 또는 플랫폼별 통합 기능(예: HomeWidget, Firebase 초기화) 수정
     - Hot Reload가 실패하거나 변경 사항이 반영되지 않을 때
3. **Execution**:
   - `send_command_input` 도구를 사용합니다.
   - 실행 중인 `flutter run` 프로세스의 ID를 대상으로 합니다.
   - 문자 'r' 또는 'R'을 전송합니다.
4. **Verification**: 명령을 보낸 후 상태를 확인하여 프로세스가 정상적으로 실행 중인지 점검합니다.

## Golden Rule
"Don't wait for the user to ask—if you changed the code and the app is running, sync it immediately."
