---
trigger: always_on
glob:
description: 코딩 스타일 및 포맷팅 규칙
---

# Coding Style Rules

## Line Length
- **최대 라인 길이**: 120자
- 120자를 초과하는 라인은 가독성을 위해 여러 줄로 나누어야 합니다.

## When to Keep Code on One Line
1. **120자 이하인 경우**
2. **단순한 할당 또는 연산**
3. **의도가 명확한 경우**
4. **짧은 메서드 체이닝 (메서드 2개 이하)**

## When to Split into Multiple Lines
1. **120자를 초과하는 경우**
2. **복잡한 조건문**
3. **함수 인자가 3개 이상인 경우**
4. **긴 메서드 체이닝**
5. **중첩된 표현식**

## Examples

### ✅ 좋음: 한 줄 (120자 미만)
```dart
final translatedTitle = AppLocaleProvider.translations[currentLang]?[baseAction.title] ?? baseAction.title;
await prefs.setString('key', value);
state.history = Map.from(state.history)..[today] = state.count;
```

### ✅ 좋음: 여러 줄 (120자 초과 또는 복잡한 경우)
```dart
// 긴 조건문
if (currentState != null && 
    newState.count > currentState.count && 
    newState.lastTapTime != null) {
  // ...
}

// 여러 개의 인자
_buildSettingsTile(
  context,
  title: localeProvider.tr('language'),
  value: _getLanguageName(localeProvider.locale, localeProvider),
  icon: LucideIcons.globe,
  isDark: isDark,
  onTap: () => _showLanguagePicker(context),
);

// 복잡한 삼항 연산자
final historyDateKey = force && _currentDateStr == today
    ? DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0]
    : _currentDateStr;
```

## Code Cleanup

### 항상 확인 및 정리할 사항:
1. **과도한 빈 줄**: 연속된 빈 줄이 2개 이상이면 제거하고, 최대 1개만 유지합니다.
2. **고립된 주석**: 코드 삭제 후 문맥을 잃은 주석을 제거합니다.
3. **행 끝 공백**: 줄 끝의 불필요한 공백을 제거합니다.
4. **일관되지 않은 간격**: 연산자와 중괄호 주변의 간격을 일관되게 유지합니다.

### Examples

#### ❌ 정리 전
```dart
void someFunction() {
  doSomething();


  // 삭제된 코드를 위한 주석
  

  doSomethingElse();
}
```

#### ✅ 정리 후
```dart
void someFunction() {
  doSomething();
  doSomethingElse();
}
```

## Golden Rule
**"코드 리뷰어가 스크롤 없이 한눈에 이해할 수 있는가?"**
- **예** → 한 줄로 유지 ✅
- **아니요** → 여러 줄로 나누기 ✅
