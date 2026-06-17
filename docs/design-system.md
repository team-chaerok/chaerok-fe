# Design System Guide

본 문서는 Chaerok Flutter 프로젝트의 디자인 시스템 구조와 사용 규칙을 정의한다.

디자인 시스템의 목적은 다음과 같다.

- 화면 간 UI 일관성 유지
- 색상, 폰트, 간격, radius 등 스타일 중복 제거
- 공통 컴포넌트 재사용
- 디자인 변경 시 수정 범위 최소화
- 협업 시 UI 구현 기준 통일

---

## 1. 기본 구조

디자인 시스템은 `core/design_system`과 `shared/widgets`로 나누어 관리한다.

```text
lib/
├── core/
│   └── design_system/
│       ├── chaerok_colors.dart
│       ├── chaerok_typography.dart
│       ├── chaerok_spacing.dart
│       ├── chaerok_radius.dart
│       ├── chaerok_shadows.dart
│       └── chaerok_theme.dart
│
└── shared/
    └── widgets/
        ├── chaerok_button.dart
        ├── chaerok_app_bar.dart
        ├── chaerok_card.dart
        ├── chaerok_text_field.dart
        ├── loading_view.dart
        └── empty_view.dart
```

---

## 2. 폴더 역할

| 폴더                          | 역할                                                        |
| ----------------------------- | ----------------------------------------------------------- |
| `core/design_system/`         | 색상, 폰트, 간격, radius, shadow, theme 등 디자인 토큰 관리 |
| `shared/widgets/`             | 여러 화면에서 재사용되는 공통 UI 컴포넌트 관리              |
| `features/{feature}/widgets/` | 특정 기능에서만 사용하는 UI 컴포넌트 관리                   |

---

## 3. 디자인 토큰 관리 기준

디자인 토큰은 앱 전체에서 반복적으로 사용되는 스타일 값을 의미한다.

예시:

```text
색상
폰트 스타일
간격
모서리 둥글기
그림자
테마
```

디자인 토큰은 직접 숫자나 색상값을 화면에 반복 작성하지 않기 위해 사용한다.

지양하는 방식:

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Color(0xFFFFFFFF),
    borderRadius: BorderRadius.circular(12),
  ),
)
```

권장하는 방식:

```dart
Container(
  padding: const EdgeInsets.all(ChaerokSpacing.md),
  decoration: BoxDecoration(
    color: ChaerokColors.surface,
    borderRadius: BorderRadius.circular(ChaerokRadius.md),
  ),
)
```

---

## 4. Colors

파일 위치:

```text
lib/core/design_system/chaerok_colors.dart
```

역할:

- 앱 전역 색상 관리
- 직접 `Color(0xFF...)`를 반복 작성하지 않도록 방지
- 브랜드 색상, 배경색, 텍스트 색상, 상태 색상 관리

예시:

```dart
import 'package:flutter/material.dart';

class ChaerokColors {
  const ChaerokColors._();

  static const Color primary = Color(0xFF4F7A5A);
  static const Color primaryLight = Color(0xFFEAF3ED);

  static const Color background = Color(0xFFFAFAF5);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFB0B0B0);

  static const Color border = Color(0xFFE5E5E0);
  static const Color error = Color(0xFFD73A4A);
}
```

규칙:

- 화면에서 `Color(0xFF...)` 직접 사용을 지양한다.
- 새로운 색상이 필요하면 `ChaerokColors`에 먼저 정의한다.
- 기능 전용 색상이어도 재사용 가능성이 있으면 디자인 토큰에 추가한다.

---

## 5. Typography

파일 위치:

```text
lib/core/design_system/chaerok_typography.dart
```

역할:

- 앱 전역 텍스트 스타일 관리
- 제목, 본문, 라벨, 캡션 스타일 통일

예시:

```dart
import 'package:flutter/material.dart';

class ChaerokTypography {
  const ChaerokTypography._();

  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
```

규칙:

- 화면에서 `TextStyle(fontSize: ...)`를 반복 작성하지 않는다.
- 기본 텍스트 스타일은 `Theme.of(context).textTheme` 또는 `ChaerokTypography`를 사용한다.
- 특정 화면에서만 필요한 일회성 스타일은 `copyWith`로 확장한다.

예시:

```dart
Text(
  '채록길 추천',
  style: Theme.of(context).textTheme.titleLarge,
)
```

```dart
Text(
  '현재 위치 기준',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: ChaerokColors.textSecondary,
      ),
)
```

---

## 6. Spacing

파일 위치:

```text
lib/core/design_system/chaerok_spacing.dart
```

역할:

- 앱 전역 여백 값 관리
- padding, margin, gap 값 통일

예시:

```dart
class ChaerokSpacing {
  const ChaerokSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}
```

사용 예시:

```dart
Padding(
  padding: const EdgeInsets.all(ChaerokSpacing.md),
  child: child,
)
```

```dart
const SizedBox(height: ChaerokSpacing.lg)
```

규칙:

- 기본 여백은 `ChaerokSpacing`을 우선 사용한다.
- 임의 숫자 사용은 최소화한다.
- 화면 전체 좌우 패딩은 가급적 하나의 기준값으로 통일한다.

---

## 7. Radius

파일 위치:

```text
lib/core/design_system/chaerok_radius.dart
```

역할:

- 버튼, 카드, 바텀시트 등 모서리 둥글기 기준 관리

예시:

```dart
class ChaerokRadius {
  const ChaerokRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}
```

사용 예시:

```dart
BorderRadius.circular(ChaerokRadius.md)
```

규칙:

- `BorderRadius.circular(12)`처럼 숫자를 직접 반복하지 않는다.
- 컴포넌트별 radius 기준은 디자인 토큰을 따른다.

---

## 8. Shadows

파일 위치:

```text
lib/core/design_system/chaerok_shadows.dart
```

역할:

- 카드, 바텀시트, 플로팅 요소의 그림자 스타일 관리

예시:

```dart
import 'package:flutter/material.dart';

import 'chaerok_colors.dart';

class ChaerokShadows {
  const ChaerokShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
```

사용 예시:

```dart
BoxDecoration(
  color: ChaerokColors.surface,
  boxShadow: ChaerokShadows.card,
)
```

---

## 9. Theme

파일 위치:

```text
lib/core/design_system/chaerok_theme.dart
```

역할:

- Flutter `ThemeData` 설정
- `ColorScheme`, `TextTheme`, `AppBarTheme`, `ButtonTheme` 등 앱 전역 스타일 연결

예시:

```dart
import 'package:flutter/material.dart';

import 'chaerok_colors.dart';

class ChaerokTheme {
  const ChaerokTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ChaerokColors.primary,
      primary: ChaerokColors.primary,
      surface: ChaerokColors.surface,
      error: ChaerokColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ChaerokColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: ChaerokColors.background,
        foregroundColor: ChaerokColors.textPrimary,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ChaerokColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ChaerokColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ChaerokColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ChaerokColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ChaerokColors.textPrimary,
        ),
      ),
    );
  }
}
```

`app/app.dart` 연결 예시:

```dart
import 'package:flutter/material.dart';

import 'package:chaerok/core/design_system/chaerok_theme.dart';

class ChaerokApp extends StatelessWidget {
  const ChaerokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chaerok',
      debugShowCheckedModeBanner: false,
      theme: ChaerokTheme.light,
      home: const Placeholder(),
    );
  }
}
```

---

## 10. 공통 컴포넌트 관리

공통 컴포넌트는 `shared/widgets/`에 둔다.

```text
shared/widgets/
├── chaerok_button.dart
├── chaerok_app_bar.dart
├── chaerok_card.dart
├── chaerok_text_field.dart
├── loading_view.dart
└── empty_view.dart
```

### 10.1 Button

파일 위치:

```text
lib/shared/widgets/chaerok_button.dart
```

예시:

```dart
import 'package:flutter/material.dart';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';

class ChaerokButton extends StatelessWidget {
  const ChaerokButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.isEnabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChaerokColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ChaerokColors.border,
          disabledForegroundColor: ChaerokColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChaerokRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.lg,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}
```

### 10.2 공통 위젯 분리 기준

다음 조건에 해당하면 `shared/widgets/`에 둔다.

- 여러 화면에서 반복 사용된다.
- 앱 전역 UI 패턴으로 볼 수 있다.
- 디자인 수정 시 여러 화면에 영향을 준다.
- 기능 도메인에 종속되지 않는다.

예시:

```text
ChaerokButton
ChaerokAppBar
ChaerokCard
ChaerokTextField
LoadingView
EmptyView
ErrorView
```

---

## 11. Feature 전용 위젯 기준

특정 기능에서만 사용하는 UI는 해당 feature 내부에 둔다.

예시:

```text
features/course/widgets/course_card.dart
features/course/widgets/course_stop_item.dart
features/camera/widgets/film_frame_overlay.dart
features/postcard/widgets/postcard_preview.dart
```

판단 기준:

```text
여러 기능에서 재사용된다 → shared/widgets/
특정 기능 의미가 강하다 → features/{feature}/widgets/
```

`CourseCard`처럼 여러 화면에서 쓰이더라도 course 도메인 의미가 강하면 `features/course/widgets/`에 유지할 수 있다.

---

## 12. 사용 규칙

### 12.1 화면에서 직접 스타일 값을 반복하지 않는다

지양:

```dart
Text(
  '타이틀',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F1F1F),
  ),
)
```

권장:

```dart
Text(
  '타이틀',
  style: Theme.of(context).textTheme.titleLarge,
)
```

---

### 12.2 여백은 토큰을 우선 사용한다

지양:

```dart
const SizedBox(height: 17)
```

권장:

```dart
const SizedBox(height: ChaerokSpacing.md)
```

---

### 12.3 색상은 토큰을 우선 사용한다

지양:

```dart
color: Color(0xFF4F7A5A)
```

권장:

```dart
color: ChaerokColors.primary
```

---

### 12.4 공통 컴포넌트는 재사용한다

지양:

```dart
ElevatedButton(
  onPressed: onPressed,
  child: Text('시작하기'),
)
```

권장:

```dart
ChaerokButton(
  text: '시작하기',
  onPressed: onPressed,
)
```

---

## 13. 네이밍 규칙

### 파일명

파일명은 `snake_case`를 사용한다.

```text
chaerok_colors.dart
chaerok_button.dart
course_card.dart
```

### 클래스명

클래스명은 `PascalCase`를 사용한다.

```dart
class ChaerokColors {}
class ChaerokButton extends StatelessWidget {}
class CourseCard extends StatelessWidget {}
```

### 디자인 시스템 클래스명

디자인 시스템 클래스는 `Chaerok` prefix를 붙인다.

```text
ChaerokColors
ChaerokTypography
ChaerokSpacing
ChaerokRadius
ChaerokShadows
ChaerokTheme
```

공통 위젯도 동일하게 `Chaerok` prefix를 붙인다.

```text
ChaerokButton
ChaerokAppBar
ChaerokCard
ChaerokTextField
```

---

## 14. 새 컴포넌트 추가 규칙

새 공통 컴포넌트를 추가할 때는 다음 기준을 따른다.

1. 여러 화면에서 사용될 가능성이 있는가?
2. 디자인 토큰을 사용하고 있는가?
3. 특정 feature에 강하게 종속되어 있지 않은가?
4. 이름만 보고 역할을 알 수 있는가?
5. 불필요하게 많은 옵션을 받지 않는가?

예시:

```text
shared/widgets/chaerok_button.dart
```

컴포넌트가 너무 많은 옵션을 가지기 시작하면 역할을 분리한다.

예시:

```text
ChaerokButton
ChaerokOutlinedButton
ChaerokIconButton
```

---

## 15. PR 체크리스트

디자인 시스템 관련 작업 전후로 다음 항목을 확인한다.

```text
[ ] 화면에서 직접 색상값을 반복 작성하지 않았는가?
[ ] 화면에서 직접 폰트 크기를 반복 작성하지 않았는가?
[ ] 여백, radius 값은 디자인 토큰을 우선 사용했는가?
[ ] 여러 화면에서 쓰이는 UI를 feature 내부에 중복 작성하지 않았는가?
[ ] 특정 feature 전용 UI를 shared에 넣지 않았는가?
[ ] 공통 컴포넌트 이름은 Chaerok prefix를 따르는가?
[ ] ThemeData에 반영해야 하는 스타일을 개별 화면에만 작성하지 않았는가?
```

---

## 16. 최종 요약

디자인 시스템은 다음 기준으로 관리한다.

```text
core/design_system/ → 디자인 토큰, ThemeData
shared/widgets/     → 공통 UI 컴포넌트
features/*/widgets/ → 기능 전용 UI 컴포넌트
```

핵심 원칙은 다음과 같다.

```text
색상, 폰트, 간격, radius는 직접 반복하지 않는다.
공통 UI는 shared/widgets에 둔다.
기능 전용 UI는 features 내부에 둔다.
앱 전체 스타일은 ChaerokTheme으로 관리한다.
```
