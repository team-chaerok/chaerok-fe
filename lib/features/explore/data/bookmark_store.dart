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
    required this.latitude,
    required this.longitude,
    this.imageUrl,
  });

  factory BookmarkedPlace.fromExplorePlace(ExplorePlace place) {
    return BookmarkedPlace(
      identityKey: place.identityKey,
      title: place.title,
      categoryLabel: place.categoryDetailLabel,
      latitude: place.latitude,
      longitude: place.longitude,
      imageUrl: place.imageUrl,
    );
  }

  factory BookmarkedPlace.fromJson(Map<String, dynamic> json) {
    return BookmarkedPlace(
      identityKey: json['identityKey'] as String,
      title: json['title'] as String,
      categoryLabel: json['categoryLabel'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String identityKey;
  final String title;
  final String categoryLabel;
  final double latitude;
  final double longitude;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'identityKey': identityKey,
    'title': title,
    'categoryLabel': categoryLabel,
    'latitude': latitude,
    'longitude': longitude,
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
  Future<bool> toggle(BookmarkedPlace place) async {
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
