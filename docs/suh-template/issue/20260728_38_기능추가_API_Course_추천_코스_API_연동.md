# ⚙️[기능추가][API] Course 추천 코스 API 연동

라벨: 작업전
담당자: (미지정)

---

## 📝 현재 문제점

- 현재 앱에는 Course(코스) 관련 API 연동이 전혀 구현되어 있지 않음 (lib/data/remote, lib/data/models 어디에도 course 관련 코드 없음)
- 사용자에게 추천 코스를 제공하거나, 사용자가 선택한 코스를 생성/조회하는 기능을 사용할 수 없음

## 🛠️ 해결 방안 / 제안 기능

- 아래 Course 관련 API를 앱에 연동한다
  - `POST /api/courses` — 사용자 선택 코스 생성
  - `POST /api/courses/active/places` — ACTIVE 코스 장소 추가
  - `GET /api/courses/recommend` — 추천 코스 후보 조회
  - `GET /api/courses/active` — ACTIVE 코스 조회
- 기존 도메인(`lib/data/remote/places_api.dart`, `users_api.dart` 등)의 패턴(static 클래스 + `DioClient.instance` 호출, 별도 repository/DI 계층 없음)을 그대로 따른다

## ⚙️ 작업 내용

- `lib/data/remote/courses_api.dart` 생성 — `CoursesApi` static 클래스, 4개 엔드포인트 메서드 구현
- `lib/data/models/` 하위 course 관련 request/response 모델 작성 (수동 `fromJson`, 기존 모델 스타일 준수)
- 각 엔드포인트 연동 확인 (성공/에러 응답 처리 포함)

## 🙋‍♂️ 담당자

- 백엔드: 이름
- 프론트엔드: @SeoHyun1024
- 디자인: 이름
