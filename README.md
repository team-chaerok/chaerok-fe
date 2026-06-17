# chaerok-fe

## 프로젝트 구조

본 프로젝트는 Flutter 기반 앱으로, 기능 단위 확장성과 협업 효율성을 위해 다음 구조를 사용합니다.

```text
lib/
├── main.dart
├── app/
├── core/
├── shared/
├── features/
└── data/
```

### 폴더 역할

| 폴더        | 역할                                             |
| ----------- | ------------------------------------------------ |
| `app/`      | 앱 실행, 라우팅, 전역 초기 설정                  |
| `core/`     | 앱 전체에서 사용하는 기반 코드                   |
| `shared/`   | 여러 기능에서 재사용되는 공통 위젯, 모델, 서비스 |
| `features/` | 화면과 기능 단위 코드                            |
| `data/`     | API, 로컬 저장소, DTO 등 데이터 연결부           |

### 기본 규칙

- 특정 기능에만 사용되는 코드는 `features/{기능명}/`에 둡니다.
- 여러 기능에서 재사용되는 코드는 `shared/`에 둡니다.
- 앱 전역 설정, 테마, 네트워크, 상수, 유틸은 `core/`에 둡니다.
- API 응답 DTO와 데이터 소스 코드는 `data/`에 둡니다.
- 화면에서는 API를 직접 호출하지 않고, `Controller → Repository → Datasource` 흐름을 따릅니다.

자세한 프로젝트 구조 규칙은 [Project Structure Guide](docs/project-structure.md)를 참고합니다.
