# Flutter 프로젝트 구조 규칙

본 문서는 `chaerok` Flutter 프로젝트의 폴더 구조와 파일 배치 규칙을 정의한다.
프로젝트는 기능 단위 확장성과 협업 효율성을 위해 다음 구조를 기준으로 관리한다.

```text
lib/
├── main.dart
├── app/
├── core/
├── shared/
├── features/
└── data/
```

---

## 1. 기본 원칙

프로젝트 구조는 다음 기준으로 나눈다.

```text
app      → 앱 실행, 라우팅, 전역 초기 설정
core     → 앱 전체 기반 코드
shared   → 여러 기능에서 재사용되는 공통 요소
features → 실제 화면과 기능 단위 코드
data     → 외부 API, 로컬 저장소, DTO 등 데이터 연결부
```

파일을 추가할 때는 먼저 아래 기준으로 판단한다.

```text
특정 기능에만 쓰인다 → features/{기능명}/
여러 기능에서 재사용된다 → shared/
앱 전체 기반 코드다 → core/
API, 로컬 저장소, 응답 DTO다 → data/
라우팅 또는 앱 초기 설정이다 → app/
```

---

## 2. 전체 폴더 구조

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── app_startup.dart
│
├── core/
│   ├── constants/
│   ├── theme/
│   ├── network/
│   ├── config/
│   ├── utils/
│   └── errors/
│
├── shared/
│   ├── widgets/
│   ├── models/
│   └── services/
│
├── features/
│   ├── splash/
│   ├── onboarding/
│   ├── home/
│   ├── course/
│   ├── place/
│   ├── camera/
│   ├── album/
│   ├── postcard/
│   └── mypage/
│
└── data/
    ├── datasources/
    └── dto/
```

---

## 3. `main.dart`

`main.dart`는 앱 진입점만 담당한다.

### 역할

- Flutter binding 초기화
- 환경 설정 초기화
- 앱 실행

### 예시

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppStartup.initialize();

  runApp(const ChaerokApp());
}
```

### 규칙

`main.dart`에는 화면, API 호출, 비즈니스 로직을 직접 작성하지 않는다.

---

## 4. `app/`

`app` 폴더는 앱 전체 실행 구조를 담당한다.

```text
app/
├── app.dart
├── router.dart
└── app_startup.dart
```

### 파일 역할

| 파일               | 역할                             |
| ------------------ | -------------------------------- |
| `app.dart`         | `MaterialApp`, 테마, 라우터 연결 |
| `router.dart`      | 화면 라우팅 정의                 |
| `app_startup.dart` | 앱 실행 전 초기화 로직           |

### 예시

```text
app/app.dart
app/router.dart
app/app_startup.dart
```

### 규칙

- 앱 전역 설정은 `app/`에 둔다.
- 특정 화면 로직은 `app/`에 두지 않는다.
- 라우트 경로는 `router.dart`에서 관리한다.

---

## 5. `core/`

`core`는 앱 전체에서 사용하는 기반 코드를 관리한다.
특정 기능에 종속되지 않는 코드만 둔다.

```text
core/
├── constants/
├── theme/
├── network/
├── config/
├── utils/
└── errors/
```

### 5.1 `core/constants/`

앱 전역 상수를 관리한다.

```text
core/constants/
├── app_colors.dart
├── app_sizes.dart
├── app_assets.dart
└── app_strings.dart
```

예시:

```dart
class AppSizes {
  static const double screenPadding = 20;
  static const double cardRadius = 16;
}
```

### 5.2 `core/theme/`

앱 테마를 관리한다.

```text
core/theme/
└── app_theme.dart
```

### 5.3 `core/network/`

네트워크 기반 코드를 관리한다.

```text
core/network/
├── api_client.dart
├── api_exception.dart
└── api_result.dart
```

역할:

- 공통 API 클라이언트
- HTTP 에러 처리
- API 응답 래핑
- 공통 header 설정

### 5.4 `core/config/`

환경 설정을 관리한다.

```text
core/config/
└── env.dart
```

예시:

```dart
class Env {
  static const String baseUrl = String.fromEnvironment('BASE_URL');
}
```

### 5.5 `core/utils/`

범용 유틸 함수를 관리한다.

```text
core/utils/
├── date_formatter.dart
├── logger.dart
└── location_utils.dart
```

규칙:

- 특정 기능 전용 유틸은 `features/{기능명}/`에 둔다.
- 앱 전체에서 재사용되는 유틸만 `core/utils/`에 둔다.

### 5.6 `core/errors/`

공통 에러 타입을 관리한다.

```text
core/errors/
└── failure.dart
```

---

## 6. `shared/`

`shared`는 여러 기능에서 재사용되는 요소를 관리한다.

```text
shared/
├── widgets/
├── models/
└── services/
```

### 6.1 `shared/widgets/`

공통 UI 컴포넌트를 관리한다.

```text
shared/widgets/
├── common_button.dart
├── common_app_bar.dart
├── loading_view.dart
├── empty_view.dart
└── error_view.dart
```

예시:

```dart
class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
```

### 6.2 `shared/models/`

여러 기능에서 함께 쓰는 모델을 관리한다.

```text
shared/models/
└── coordinate.dart
```

예시:

```dart
class Coordinate {
  const Coordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
```

### 6.3 `shared/services/`

여러 기능에서 사용하는 서비스 코드를 관리한다.

```text
shared/services/
├── location_service.dart
├── permission_service.dart
└── image_picker_service.dart
```

규칙:

- 특정 기능 전용 서비스는 해당 `features` 내부에 둔다.
- 위치, 권한, 이미지 선택처럼 여러 기능에서 쓰는 서비스만 `shared/services/`에 둔다.

---

## 7. `features/`

`features`는 실제 기능 단위 코드를 관리한다.
각 기능은 독립적인 폴더를 가진다.

```text
features/
├── splash/
├── onboarding/
├── home/
├── course/
├── place/
├── camera/
├── album/
├── postcard/
└── mypage/
```

각 feature 내부는 기본적으로 다음 구조를 따른다.

```text
features/{feature_name}/
├── screens/
├── widgets/
├── models/
├── controllers/
└── repositories/
```

단, 필요 없는 폴더는 만들지 않는다.
예를 들어 단순 화면만 있는 기능이면 `screens/`만 있어도 된다.

---

## 8. Feature 내부 규칙

### 8.1 `screens/`

화면 단위 위젯을 관리한다.

```text
features/course/screens/
├── course_list_screen.dart
└── course_detail_screen.dart
```

규칙:

- 하나의 파일은 하나의 주요 화면을 담당한다.
- 화면 파일명은 `{기능명}_{역할}_screen.dart` 형식을 사용한다.
- 화면 내부에 복잡한 UI가 길어지면 `widgets/`로 분리한다.

### 8.2 `widgets/`

해당 기능에서만 사용하는 UI 컴포넌트를 관리한다.

```text
features/course/widgets/
├── course_card.dart
└── course_stop_item.dart
```

규칙:

- `course`에서만 쓰는 위젯은 `features/course/widgets/`에 둔다.
- 여러 기능에서 쓰게 되면 `shared/widgets/`로 이동한다.

### 8.3 `models/`

해당 기능에서만 사용하는 모델을 관리한다.

```text
features/course/models/
├── course.dart
└── course_stop.dart
```

규칙:

- 화면 표시용 모델 또는 도메인 모델을 둔다.
- API 응답 DTO는 `data/dto/`에 둔다.
- DTO와 화면 모델은 분리한다.

### 8.4 `controllers/`

화면 상태와 사용자 액션 처리 로직을 관리한다.

```text
features/course/controllers/
└── course_controller.dart
```

역할:

- 화면 상태 관리
- 로딩, 에러, 성공 상태 처리
- repository 호출
- 사용자 이벤트 처리

규칙:

- `BuildContext` 의존은 최소화한다.
- API 직접 호출은 하지 않는다.
- 데이터 요청은 repository를 통해 수행한다.

### 8.5 `repositories/`

기능 단위 데이터 접근 로직을 관리한다.

```text
features/course/repositories/
└── course_repository.dart
```

역할:

- datasource 호출
- DTO를 화면 모델로 변환
- 기능 단위 데이터 흐름 관리

규칙:

- API 호출 세부 구현은 `data/datasources/`에 둔다.
- repository는 feature에서 사용할 수 있는 형태로 데이터를 정리한다.

---

## 9. `data/`

`data`는 외부 데이터 연결부를 관리한다.

```text
data/
├── datasources/
└── dto/
```

### 9.1 `data/datasources/`

API, 로컬 DB, SharedPreferences 등 실제 데이터 소스를 관리한다.

```text
data/datasources/
├── tour_api_datasource.dart
├── local_storage_datasource.dart
└── photo_local_datasource.dart
```

역할:

- HTTP 요청
- 로컬 저장소 접근
- 외부 SDK 데이터 조회

규칙:

- datasource는 원천 데이터를 가져오는 역할만 한다.
- 화면에서 바로 datasource를 호출하지 않는다.
- feature의 repository를 통해 접근한다.

### 9.2 `data/dto/`

API 응답/요청 DTO를 관리한다.

```text
data/dto/
├── tour_place_response.dart
├── course_response.dart
└── postcard_response.dart
```

규칙:

- 서버 또는 외부 API 응답 구조와 맞춘다.
- 화면에서 직접 DTO를 사용하지 않는다.
- repository에서 DTO를 feature model로 변환한다.

---

## 10. Chaerok 기능별 기본 구조

### 10.1 Home

```text
features/home/
├── screens/
│   └── home_screen.dart
├── widgets/
│   ├── current_location_card.dart
│   └── recommended_course_card.dart
└── controllers/
    └── home_controller.dart
```

역할:

- 현재 위치 기반 추천
- 메인 진입 화면
- 추천 코스/장소 요약 표시

---

### 10.2 Course

```text
features/course/
├── screens/
│   ├── course_list_screen.dart
│   └── course_detail_screen.dart
├── widgets/
│   ├── course_card.dart
│   └── course_stop_item.dart
├── models/
│   ├── course.dart
│   └── course_stop.dart
├── repositories/
│   └── course_repository.dart
└── controllers/
    └── course_controller.dart
```

역할:

- 채록길 목록
- 채록길 상세
- 코스 내 장소 목록
- 사용자 위치 기준 코스 추천

---

### 10.3 Place

```text
features/place/
├── screens/
│   ├── place_list_screen.dart
│   └── place_detail_screen.dart
├── widgets/
│   └── place_card.dart
├── models/
│   └── place.dart
├── repositories/
│   └── place_repository.dart
└── controllers/
    └── place_controller.dart
```

역할:

- 관광지 목록
- 장소 상세 정보
- 유적지/문화시설 정보 표시
- 위치 기반 장소 판별

---

### 10.4 Camera

```text
features/camera/
├── screens/
│   └── camera_screen.dart
├── widgets/
│   └── film_frame_overlay.dart
└── controllers/
    └── camera_controller.dart
```

역할:

- 필름 카메라 촬영
- 촬영 가능 여부 확인
- 촬영 UI 오버레이

---

### 10.5 Album

```text
features/album/
├── screens/
│   ├── album_screen.dart
│   └── photo_detail_screen.dart
├── widgets/
│   └── photo_grid_item.dart
├── models/
│   └── chaerok_photo.dart
└── controllers/
    └── album_controller.dart
```

역할:

- 촬영 사진 목록
- 현상 완료 사진 조회
- 사진 상세 보기

---

### 10.6 Postcard

```text
features/postcard/
├── screens/
│   └── postcard_result_screen.dart
├── widgets/
│   └── postcard_preview.dart
└── controllers/
    └── postcard_controller.dart
```

역할:

- 여행 종료 후 엽서 생성
- 장소명, 날짜, 지역 정보 표시
- 역사 테마 엽서 결과 화면

---

## 11. 파일명 규칙

파일명은 `snake_case`를 사용한다.

```text
course_detail_screen.dart
course_card.dart
course_repository.dart
course_controller.dart
```

클래스명은 `PascalCase`를 사용한다.

```dart
class CourseDetailScreen extends StatelessWidget {}

class CourseCard extends StatelessWidget {}

class CourseRepository {}

class CourseController {}
```

변수명과 함수명은 `camelCase`를 사용한다.

```dart
final courseList = <Course>[];

void fetchCourseList() {}
```

---

## 12. Import 규칙

가능하면 상대 경로보다 package import를 우선 사용한다.

```dart
import 'package:chaerok/features/course/models/course.dart';
```

권장하지 않는 방식:

```dart
import '../../models/course.dart';
```

이유:

- 파일 이동 시 경로 깨짐이 적다.
- Codex, Claude 등 자동 수정 도구가 구조를 파악하기 쉽다.
- import 경로가 명확하다.

---

## 13. Widget 분리 기준

다음 조건 중 하나라도 해당하면 별도 위젯으로 분리한다.

- 하나의 build 메서드가 너무 길어진 경우
- 같은 UI가 2번 이상 반복되는 경우
- 조건문이 많아져 화면 가독성이 떨어지는 경우
- 화면의 특정 영역이 독립적인 의미를 가지는 경우
- 다른 화면에서도 재사용 가능성이 있는 경우

예시:

```text
course_detail_screen.dart
```

내부에 코스 카드, 장소 리스트 아이템, 하단 버튼이 모두 들어가면 다음처럼 분리한다.

```text
features/course/widgets/
├── course_summary_card.dart
├── course_stop_item.dart
└── course_start_button.dart
```

---

## 14. 화면과 로직 분리 규칙

화면 파일에서는 UI 표현에 집중한다.

화면 파일에서 직접 하지 않는 것:

- API 직접 호출
- 복잡한 데이터 가공
- 로컬 저장소 직접 접근
- 긴 조건 분기
- 외부 SDK 직접 제어

권장 흐름:

```text
Screen
→ Controller
→ Repository
→ Datasource
→ API / Local Storage
```

예시:

```text
CourseDetailScreen
→ CourseController
→ CourseRepository
→ TourApiDatasource
```

---

## 15. DTO와 Model 분리 규칙

API 응답 구조와 화면에서 사용하는 모델은 분리한다.

```text
data/dto/course_response.dart
features/course/models/course.dart
```

DTO 예시:

```dart
class CourseResponse {
  final String contentId;
  final String title;
  final String addr1;
}
```

Model 예시:

```dart
class Course {
  final String id;
  final String name;
  final String address;
}
```

변환은 repository에서 수행한다.

```dart
Course toCourse(CourseResponse response) {
  return Course(
    id: response.contentId,
    name: response.title,
    address: response.addr1,
  );
}
```

---

## 16. 새 기능 추가 규칙

새 기능을 추가할 때는 다음 순서로 생성한다.

예시: `map` 기능 추가

```text
features/map/
├── screens/
│   └── map_screen.dart
├── widgets/
│   └── map_marker_view.dart
├── controllers/
│   └── map_controller.dart
├── models/
│   └── map_place.dart
└── repositories/
    └── map_repository.dart
```

단순 기능이면 최소 구조만 만든다.

```text
features/map/
└── screens/
    └── map_screen.dart
```

처음부터 사용하지 않는 폴더를 과하게 만들지 않는다.

---

## 17. 이동 기준

처음에는 feature 내부에 두고, 여러 곳에서 재사용되면 shared로 이동한다.

예시:

```text
features/course/widgets/course_card.dart
```

`home`에서도 쓰기 시작하면:

```text
shared/widgets/course_card.dart
```

단, 기능 의미가 강하면 그대로 feature에 두고 외부에서 import해도 된다.
예를 들어 `CourseCard`는 course 도메인에 강하게 연결되어 있으므로 `features/course/widgets/`에 유지할 수 있다.

---

## 18. 금지 규칙

다음 구조는 지양한다.

### 18.1 모든 화면을 screens에 몰아넣기

```text
lib/screens/
├── home_screen.dart
├── course_list_screen.dart
├── course_detail_screen.dart
├── camera_screen.dart
└── mypage_screen.dart
```

기능이 커질수록 관련 파일이 흩어지므로 사용하지 않는다.

### 18.2 common 폴더에 모든 공통 코드 넣기

```text
lib/common/
├── button.dart
├── api.dart
├── color.dart
├── course_card.dart
└── helper.dart
```

`common`은 역할이 모호해지기 쉬우므로 사용하지 않는다.
대신 `core`와 `shared`로 구분한다.

### 18.3 화면에서 API 직접 호출하기

```dart
// 지양
final response = await ApiClient.get('/courses');
```

화면은 controller를 호출하고, controller는 repository를 호출한다.

```dart
// 권장
controller.fetchCourses();
```

---

## 19. PR 작성 시 구조 체크리스트

PR을 올리기 전 다음 항목을 확인한다.

```text
[ ] 새 파일이 적절한 폴더에 위치하는가?
[ ] 특정 기능 전용 코드를 shared/core에 넣지 않았는가?
[ ] 여러 기능에서 재사용되는 코드를 feature 내부에 중복 작성하지 않았는가?
[ ] 화면 파일에 API 호출이나 복잡한 비즈니스 로직이 들어가지 않았는가?
[ ] DTO와 화면 모델이 분리되어 있는가?
[ ] 파일명은 snake_case를 따르는가?
[ ] 클래스명은 PascalCase를 따르는가?
[ ] import는 package import를 우선 사용하는가?
```

---

## 20. 최종 요약

이 프로젝트는 다음 구조를 기준으로 관리한다.

```text
lib/
├── main.dart
├── app/       # 앱 실행, 라우팅, 초기 설정
├── core/      # 앱 전체 기반 코드
├── shared/    # 재사용 가능한 공통 요소
├── features/  # 기능별 화면과 로직
└── data/      # API, 로컬 저장소, DTO
```

핵심 판단 기준은 다음과 같다.

```text
기능 전용이면 features
재사용 요소면 shared
앱 기반이면 core
데이터 연결이면 data
앱 설정이면 app
```
