import 'dart:convert';
import 'dart:developer';

import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tag = 'BookmarkStore';
const _key = 'explore_bookmarked_places';

/// 저장(북마크)한 장소 한 건. 오프라인/목록 화면에서도 카드를 그릴 수 있도록
/// 표시에 필요한 메타를 함께 보관한다.
class BookmarkedPlace {
  const BookmarkedPlace({
    required this.identityKey,
    required this.title,
    required this.categoryLabel,
    required this.categoryGroupWire,
    required this.source,
    required this.latitude,
    required this.longitude,
    this.serverId,
    this.externalPlaceId,
    this.imageUrl,
  });

  factory BookmarkedPlace.fromExplorePlace(ExplorePlace place) {
    return BookmarkedPlace(
      identityKey: place.identityKey,
      title: place.title,
      categoryLabel: place.categoryDetailLabel,
      categoryGroupWire: place.categoryGroupWire,
      source: place.source,
      latitude: place.latitude,
      longitude: place.longitude,
      serverId: place.serverId,
      externalPlaceId: place.externalPlaceId,
      imageUrl: place.imageUrl,
    );
  }

  /// [categoryGroupWire]/[source]는 커스텀 코스 생성(`CoursePlaceSaveRequest`)에
  /// 필요해 나중에 추가된 필드다. 그 전에 저장된 북마크에는 없으므로 빈 문자열로
  /// 채운다 — 해당 북마크는 "코스 만들기" 진입 시 소스 정보 부족으로 제외된다.
  factory BookmarkedPlace.fromJson(Map<String, dynamic> json) {
    return BookmarkedPlace(
      identityKey: json['identityKey'] as String,
      title: json['title'] as String,
      categoryLabel: json['categoryLabel'] as String,
      categoryGroupWire: json['categoryGroupWire'] as String? ?? '',
      source: json['source'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      serverId: json['serverId'] as int?,
      externalPlaceId: json['externalPlaceId'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String identityKey;
  final String title;
  final String categoryLabel;
  final String categoryGroupWire;
  final String source;
  final double latitude;
  final double longitude;
  final int? serverId;
  final String? externalPlaceId;
  final String? imageUrl;

  /// 커스텀 코스 생성에 쓸 수 있는지: 필드 보강 이전에 저장된 북마크는
  /// [source]가 비어 있어 서버 전송 필드를 채울 수 없다.
  bool get canBuildCourse => source.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'identityKey': identityKey,
    'title': title,
    'categoryLabel': categoryLabel,
    'categoryGroupWire': categoryGroupWire,
    'source': source,
    'latitude': latitude,
    'longitude': longitude,
    'serverId': serverId,
    'externalPlaceId': externalPlaceId,
    'imageUrl': imageUrl,
  };
}

/// 채록길 탐색 모드의 장소 북마크를 SharedPreferences에 JSON 배열로 저장하는
/// 래퍼. 서버 동기화는 범위 밖이라 로컬 전용이며, `AppPreferences`와 동일한
/// 지연 초기화 싱글턴 패턴을 따른다.
class BookmarkStore {
  BookmarkStore._();

  static BookmarkStore? _instance;

  static BookmarkStore get instance => _instance ??= BookmarkStore._();

  /// [toggle]의 읽기-수정-쓰기 구간을 직렬화하는 락. 서로 다른 장소를 빠르게
  /// 연속 토글해도 마지막 쓰기가 이전 쓰기를 덮어쓰지 않게 한다.
  Future<void> _writeLock = Future<void>.value();

  Future<List<BookmarkedPlace>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => BookmarkedPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      log('북마크 파싱 실패 - 초기화', name: _tag, error: e, stackTrace: st);
      await prefs.remove(_key);
      return const [];
    }
  }

  Future<Set<String>> bookmarkedKeys() async {
    final places = await list();
    return places.map((place) => place.identityKey).toSet();
  }

  Future<bool> isBookmarked(String identityKey) async {
    final keys = await bookmarkedKeys();
    return keys.contains(identityKey);
  }

  /// 북마크를 토글하고 토글 후 상태(true=북마크됨)를 반환한다.
  /// 읽기-수정-쓰기 전체를 [_writeLock]으로 직렬화한다.
  Future<bool> toggle(BookmarkedPlace place) {
    final result = _writeLock.then((_) => _toggleLocked(place));
    // 한 번의 실패가 이후 토글을 막지 않도록 락 체인에서는 에러를 삼킨다.
    _writeLock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _toggleLocked(BookmarkedPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await list();
    final exists = current.any((e) => e.identityKey == place.identityKey);
    final next = exists
        ? current.where((e) => e.identityKey != place.identityKey).toList()
        : [...current, place];
    await prefs.setString(
      _key,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
    return !exists;
  }
}
