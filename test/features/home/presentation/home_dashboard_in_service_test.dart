import 'package:chaerok/data/models/region_response.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_collection_screen.dart';
import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/film_collection_button.dart';
import 'package:chaerok/features/home/presentation/widgets/folder_deck/folder_card.dart';
import 'package:chaerok/features/home/presentation/widgets/my_page_button.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/settings/presentation/my_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Position _fakePosition() => Position(
  latitude: 36.4,
  longitude: 127.1,
  timestamp: DateTime(2026, 1, 1),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

LocationVerificationResult _fakeVerifiedResult() => LocationVerificationResult(
  position: _fakePosition(),
  region: const RegionResponse(
    serviceArea: true,
    regionId: 1,
    provinceName: '충청남도',
    cityCountyName: '공주시',
  ),
  places: const [],
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
    LocationVerificationResult.qaLocationDirty = false;
  });

  tearDown(() {
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
    LocationVerificationResult.qaLocationDirty = false;
  });

  // 최초 위치 인증에서 바로 LocationVerified를 주입하면 _onLocationVerified가
  // _autoConnectFilmRollEntry(로컬 DB·백엔드 동기화 의존)까지 자동으로 태우는데,
  // 이 프로젝트 테스트 스위트에는 그 경로를 위한 seam이 없어 위젯 테스트에서
  // 안전하게 완료되지 않는다(어떤 기존 테스트도 LocationVerified를 직접 주입하지
  // 않는 이유와 동일). 대신 최초 진입은 안전한 LocationOutOfService로 통과시키고,
  // QA 재판정 경로(_reevaluateLocationForQa, autoConnect:false — 날씨/근처 장소만
  // 갱신하고 필름롤 자동 연결은 타지 않음)로 서비스 지역 결과를 주입해 카드 덱
  // 렌더링만 안전하게 검증한다.
  Future<void> pumpVerifiedHome(
    WidgetTester tester,
    GlobalKey<HomeDashboardScreenState> key,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var verified = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeDashboardScreen(
          key: key,
          debugRunLocationVerification: () async => verified
              ? LocationVerified(_fakeVerifiedResult())
              : const LocationOutOfService(),
        ),
      ),
    );
    await tester.pump(); // postFrameCallback → 러너 호출(1차: out-of-service)
    await tester.pump(); // 러너 Future 완료 → 결과 반영

    verified = true;
    LocationVerificationResult.qaLocationDirty = true;
    await key.currentState!
        .refresh(); // QA 재판정(2차: LocationVerified, autoConnect:false)
    await tester.pump();
    // 날씨/내 정보 조회(Dio)가 붙인 타임아웃 타이머를 확정적으로 소진한다.
    // pumpAndSettle은 프레임 스케줄링 여부만 보고 "정착"을 판단해, 프레임을
    // 만들지 않는 순수 백그라운드 Timer가 테스트 종료 시점까지 남아
    // "Timer is still pending" 검증에 걸릴 수 있다 — 고정 시간만큼 직접
    // pump해 확실히 흘려보낸다.
    await tester.pump(const Duration(seconds: 15));
  }

  testWidgets('서비스 지역 진입 시 현재여행지역 탭이 기본으로 열려 지역명 라벨을 보여준다', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpVerifiedHome(tester, key);

    expect(find.text('공주시 필름롤'), findsOneWidget);
    expect(find.text('지난여행'), findsOneWidget); // 겹친 탭
    expect(find.text('마이페이지'), findsOneWidget); // 겹친 탭
  });

  testWidgets('현재여행지역 카드 색은 실제 지역(공주)의 필름롤 색을 쓴다', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpVerifiedHome(tester, key);

    final regionCard = tester.widget<FolderCard>(
      find.ancestor(
        of: find.text('공주시 필름롤'),
        matching: find.byType(FolderCard),
      ),
    );
    expect(regionCard.color, RegionCode.gongju.filmTabColor);
  });

  testWidgets('공주는 예산이 아니므로 라벨 색이 기본(흰색)으로 유지된다', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpVerifiedHome(tester, key);

    final regionCard = tester.widget<FolderCard>(
      find.ancestor(
        of: find.text('공주시 필름롤'),
        matching: find.byType(FolderCard),
      ),
    );
    expect(regionCard.labelColor, RegionCode.gongju.filmLabelColor);
    expect(regionCard.labelColor, isNull); // FolderCard 기본값(흰색)으로 위임
  });

  testWidgets('헤더에 필름/마이페이지 아이콘 버튼이 없다(기능이 카드 탭으로 흡수됨)', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpVerifiedHome(tester, key);

    expect(find.byType(FilmCollectionButton), findsNothing);
    expect(find.byType(MyPageButton), findsNothing);
  });

  testWidgets('겹친 "지난여행" 탭을 누르면 카드 안에서 인라인으로 필름 컬렉션이 열린다', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpVerifiedHome(tester, key);

    await tester.tap(find.text('지난여행'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // 스왑 전환(320ms) 완료 대기

    expect(find.byType(FilmRollCollectionScreen), findsOneWidget);
    // 카드가 이미 헤더(탭 라벨)를 가지므로 자체 앱바는 그리지 않는다.
    expect(find.text('필름 컬렉션'), findsNothing);
    expect(find.text('공주시 필름롤'), findsOneWidget); // 현재여행지역은 이제 겹친 탭으로
  });

  testWidgets('겹친 "마이페이지" 탭을 누르면 카드 안에서 인라인으로 MyScreen이 열린다', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpVerifiedHome(tester, key);

    await tester.tap(find.text('마이페이지'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(
      const Duration(seconds: 15),
    ); // MyScreen 자체 사용자 조회(Dio) 소진

    expect(find.byType(MyScreen), findsOneWidget);
  });
}
