import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/shared/widgets/course_map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CoursePlaceResponse _place({
  String title = '테스트 장소',
  double? latitude,
  double? longitude,
}) {
  return CoursePlaceResponse(
    source: 'kakao',
    title: title,
    categoryGroup: '카페',
    address: '주소',
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  group('CourseMapMarker.fromCoursePlaces', () {
    test('좌표가 있는 장소는 모두 마커로 변환된다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(title: 'A', latitude: 37.1, longitude: 127.1),
        _place(title: 'B', latitude: 37.2, longitude: 127.2),
      ]);

      expect(markers, hasLength(2));
      expect(markers[0].title, 'A');
      expect(markers[1].title, 'B');
    });

    test('좌표가 둘 다 없는 장소는 건너뛴다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(latitude: 37.1, longitude: 127.1),
        _place(),
      ]);

      expect(markers, hasLength(1));
    });

    test('latitude가 NaN이면 건너뛴다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(latitude: double.nan, longitude: 127.1),
      ]);

      expect(markers, isEmpty);
    });

    test('longitude가 Infinity이면 건너뛴다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(latitude: 37.1, longitude: double.infinity),
      ]);

      expect(markers, isEmpty);
    });

    test('latitude가 유효 범위(-90~90)를 벗어나면 건너뛴다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(latitude: 90.1, longitude: 127.1),
      ]);

      expect(markers, isEmpty);
    });

    test('longitude가 유효 범위(-180~180)를 벗어나면 건너뛴다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(latitude: 37.1, longitude: -180.1),
      ]);

      expect(markers, isEmpty);
    });

    test('경계값(latitude 90, longitude 180)은 유효한 좌표로 포함된다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(latitude: 90, longitude: 180),
      ]);

      expect(markers, hasLength(1));
    });

    test('order는 필터링 여부와 무관하게 원래 목록에서의 위치(1-based)를 유지한다', () {
      final markers = CourseMapMarker.fromCoursePlaces([
        _place(title: '첫 번째', latitude: 37.1, longitude: 127.1),
        _place(title: '좌표없음'),
        _place(title: '세 번째', latitude: 37.3, longitude: 127.3),
      ]);

      expect(markers, hasLength(2));
      expect(markers[0].order, 1);
      expect(markers[1].order, 3);
    });
  });

  group('CourseMapView', () {
    testWidgets('유효 좌표가 하나도 없으면 지도 대신 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: CourseMapView(places: [_place()])),
      );

      expect(find.text('지도에 표시할 위치 정보가 없어요'), findsOneWidget);
    });
  });
}
