---
trigger: always_on
glob:
description: Daily App을 Google Play Store에 빌드 및 배포하기 위한 가이드
---

# Play Store Build Guide

## 1. Versioning
- **버전 이름**: `pubspec.yaml`에서 관리합니다. (예: `1.2.1`)
- **버전 코드**: 빌드 과정에서 빌드 옵션으로 제공됩니다.

## 2. Signing
앱은 서명을 위해 `android/key.properties`를 사용합니다.
- 키스토어(Keystore): `android/app/didit-keystore.jks`
- 키 별칭(Key Alias): `didit`

## 3. API Keys
Firebase API 키는 `lib/config/api_keys.dart`에 저장됩니다.
이 파일은 보안을 위해 Git에서 **제외**되어 있습니다.
모든 키가 Google Cloud Console에서 올바르게 제한되었는지 확인하십시오.

## 4. Build Command
특정 버전 코드(예: 11)로 릴리스용 App Bundle을 생성하려면:
```bash
flutter build appbundle --release --build-number=11 --no-tree-shake-icons
```
*주의: 앱이 동적 IconData를 사용하므로 `--no-tree-shake-icons` 플래그가 반드시 필요합니다.*
*주의: 버전 이름은 `pubspec.yaml`에서 자동으로 가져옵니다.*
*설명: 위 명령은 특정 버전 코드(예: 11)로 배포용 앱 번들을 생성합니다.*

## 5. Deployment
1. 빌드가 완료되면 `.aab` 파일이 다음 위치에 생성됩니다:
   `build/app/outputs/bundle/release/app-release.aab`
2. **Rule**: 업로드 전 쉽게 접근할 수 있도록 이 파일을 **홈 디렉토리**로 복사하십시오:
   ```bash
   cp build/app/outputs/bundle/release/app-release.aab ~/app-release-11.aab
   ```
3. 파일을 Google Play Console에 업로드하십시오.

## 6. Release Notes Guidelines
릴리즈 노트 작성 시 다음 규칙을 따르십시오:
1. **기준**: 항상 가장 최근 **Tag** 이후의 커밋 내용을 기준으로 작성합니다.
2. **언어**: **한국어, 영어, 일본어** 3개 언어로 작성합니다.
3. **내용**: 사용자에게 직접적으로 영향을 주는 변경 사항(새 기능, 버그 수정, UI 개선 등)만 포함하며, 내부적인 변경(리팩토링, 문서 수정 등)은 제외합니다.
4. **형식**: 문장은 최대한 간결하고 명확하게 작성합니다.

### 예시
- **KR**: 홈 위젯 카운트 버그 수정 및 UI 개선
- **EN**: Fixed home widget count bug and improved UI
- **JP**: ホームウィジェットのカウントバグ修正およびUI改善
