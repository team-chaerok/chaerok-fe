import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = CoursePlaceResponse(
  source: 'kakao',
  title: '테스트 장소',
  categoryGroup: '카페',
  address: '주소',
);

void main() {
  test('좌표가 있으면 그대로 보존된다', () {
    final place = CourseCandidatePlace.fromCoursePlaceResponse(
      const CoursePlaceResponse(
        source: 'kakao',
        title: '테스트 장소',
        categoryGroup: '카페',
        address: '주소',
        latitude: 37.1,
        longitude: 127.1,
      ),
      visitOrder: 0,
    );

    expect(place.latitude, 37.1);
    expect(place.longitude, 127.1);
  });

  test('좌표가 둘 다 없으면 0으로 대체되지 않고 예외가 발생한다', () {
    expect(
      () => CourseCandidatePlace.fromCoursePlaceResponse(_base, visitOrder: 0),
      throwsA(isA<InvalidCoursePlaceException>()),
    );
  });

  test('longitude만 없어도 예외가 발생한다', () {
    expect(
      () => CourseCandidatePlace.fromCoursePlaceResponse(
        const CoursePlaceResponse(
          source: 'kakao',
          title: '테스트 장소',
          categoryGroup: '카페',
          address: '주소',
          latitude: 37.1,
        ),
        visitOrder: 0,
      ),
      throwsA(isA<InvalidCoursePlaceException>()),
    );
  });

  test('latitude가 NaN이면 예외가 발생한다', () {
    expect(
      () => CourseCandidatePlace.fromCoursePlaceResponse(
        const CoursePlaceResponse(
          source: 'kakao',
          title: '테스트 장소',
          categoryGroup: '카페',
          address: '주소',
          latitude: double.nan,
          longitude: 127.1,
        ),
        visitOrder: 0,
      ),
      throwsA(isA<InvalidCoursePlaceException>()),
    );
  });

  test('longitude가 Infinity이면 예외가 발생한다', () {
    expect(
      () => CourseCandidatePlace.fromCoursePlaceResponse(
        const CoursePlaceResponse(
          source: 'kakao',
          title: '테스트 장소',
          categoryGroup: '카페',
          address: '주소',
          latitude: 37.1,
          longitude: double.infinity,
        ),
        visitOrder: 0,
      ),
      throwsA(isA<InvalidCoursePlaceException>()),
    );
  });

  test('latitude가 90을 초과하면 예외가 발생한다', () {
    expect(
      () => CourseCandidatePlace.fromCoursePlaceResponse(
        const CoursePlaceResponse(
          source: 'kakao',
          title: '테스트 장소',
          categoryGroup: '카페',
          address: '주소',
          latitude: 90.1,
          longitude: 127.1,
        ),
        visitOrder: 0,
      ),
      throwsA(isA<InvalidCoursePlaceException>()),
    );
  });

  test('longitude가 -180 미만이면 예외가 발생한다', () {
    expect(
      () => CourseCandidatePlace.fromCoursePlaceResponse(
        const CoursePlaceResponse(
          source: 'kakao',
          title: '테스트 장소',
          categoryGroup: '카페',
          address: '주소',
          latitude: 37.1,
          longitude: -180.1,
        ),
        visitOrder: 0,
      ),
      throwsA(isA<InvalidCoursePlaceException>()),
    );
  });

  test('fromExplorePlace: ExplorePlace.imageUrl이 그대로 옮겨진다', () {
    const explorePlace = ExplorePlace(
      title: '테스트 장소',
      address: '주소',
      latitude: 37.1,
      longitude: 127.1,
      categoryGroup: PlaceCategoryGroup.tourism,
      categoryGroupWire: 'TOURISM',
      categoryDetail: PlaceCategoryDetail.heritage,
      categoryDetailLabel: '역사',
      source: 'TOUR_API',
      identityKey: 'key',
      imageUrl: 'https://example.com/photo.jpg',
    );

    final place = CourseCandidatePlace.fromExplorePlace(
      explorePlace,
      visitOrder: 0,
    );

    expect(place.imageUrl, 'https://example.com/photo.jpg');
  });

  test('경계값(latitude 90, longitude 180)은 유효한 좌표로 보존된다', () {
    final place = CourseCandidatePlace.fromCoursePlaceResponse(
      const CoursePlaceResponse(
        source: 'kakao',
        title: '테스트 장소',
        categoryGroup: '카페',
        address: '주소',
        latitude: 90,
        longitude: 180,
      ),
      visitOrder: 0,
    );

    expect(place.latitude, 90);
    expect(place.longitude, 180);
  });
}
