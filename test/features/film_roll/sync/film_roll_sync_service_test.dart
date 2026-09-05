import 'dart:io';
import 'dart:typed_data';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/film_roll_create_request.dart';
import 'package:chaerok/data/models/film_roll_photo_list_response.dart';
import 'package:chaerok/data/models/film_roll_photo_response.dart';
import 'package:chaerok/data/models/film_roll_response.dart';
import 'package:chaerok/data/models/photo_complete_response.dart';
import 'package:chaerok/data/models/photo_upload_url_request.dart';
import 'package:chaerok/data/models/photo_upload_url_response.dart';
import 'package:chaerok/data/models/visit_create_request.dart';
import 'package:chaerok/data/models/visit_create_response.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_place_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/photo_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

FilmRollResponse _fakeResponse({int id = 900, String status = 'CAPTURING'}) =>
    FilmRollResponse(
      filmRollId: id,
      regionId: 11,
      filterId: 'f1',
      filterStrength: 1.0,
      filterVersion: 1,
      status: status,
      totalPhotoCount: 0,
      processedPhotoCount: 0,
      maxPhotoCount: 24,
      exitConfirmed: false,
      developAvailable: false,
      createdAt: DateTime(2026, 8, 30),
      updatedAt: DateTime(2026, 8, 30),
    );

DioException _dioError(
  int statusCode, {
  String message = '오류',
  String? code,
  List<String> fields = const [],
}) => DioException(
  requestOptions: RequestOptions(path: '/api/film-rolls'),
  error: ApiError(
    statusCode: statusCode,
    message: message,
    errorCode: code,
    fields: fields,
  ),
);

PhotoUploadUrlResponse _uploadUrlResponse({
  required int photoId,
  required int sequence,
}) => PhotoUploadUrlResponse(
  photoId: photoId,
  filmRollId: 900,
  sequence: sequence,
  objectKey: 'users/1/film-rolls/900/photos/$sequence/original.jpg',
  uploadUrl: 'https://bucket.s3.example.com/put?sig=abc',
  expiresAt: DateTime(2026, 9, 6, 15),
  requiredHeaders: const {
    'content-type': ['image/jpeg'],
  },
);

PhotoCompleteResponse _completeResponse({required int photoId}) =>
    PhotoCompleteResponse(
      photoId: photoId,
      filmRollId: 900,
      sequence: 1,
      status: 'UPLOADED',
      totalPhotoCount: 1,
    );

FilmRollPhotoResponse _serverPhoto({
  required int photoId,
  required int sequence,
  String status = 'UPLOADED',
}) => FilmRollPhotoResponse(
  photoId: photoId,
  sequence: sequence,
  status: status,
  takenAt: DateTime(2026, 9, 6, 14),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late FilmRollRepositoryImpl repository;
  late FilmRollPlaceRepositoryImpl placeRepository;
  late PhotoRepositoryImpl photoRepository;
  late AppPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'current_user_id': 1});
    prefs = AppPreferences.instance;
    tempDir = await Directory.systemTemp.createTemp('film_roll_sync_service');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FilmRollRepositoryImpl(
      database: database,
      filmRollDataSource: FilmRollLocalDataSource(database),
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );
    placeRepository = FilmRollPlaceRepositoryImpl(
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
    );
    photoRepository = PhotoRepositoryImpl(
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );
  });

  /// 로컬 사진 행을 직접 심는다(파일 인코딩 없이). serverPhotoId는 null이라
  /// 동기화가 업로드 대상으로 잡는다.
  Future<void> seedPhoto(
    String filmRollId,
    String placeId, {
    required int sequence,
  }) {
    return database
        .into(database.photos)
        .insert(
          PhotosCompanion.insert(
            id: 'photo-$filmRollId-$sequence',
            filmRollId: filmRollId,
            filmRollPlaceId: placeId,
            originalPath: '/tmp/p$sequence-original.jpg',
            thumbnailPath: '/tmp/p$sequence-thumb.jpg',
            takenAt: DateTime(2026, 9, 6, 14, sequence),
            sequence: Value(sequence),
          ),
        );
  }

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  Future<FilmRoll> seedFilmRoll({int regionId = 11}) {
    return repository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
      regionId: regionId,
    );
  }

  FilmRollSyncService service({
    Future<FilmRollResponse> Function(FilmRollCreateRequest)? createFilmRoll,
    Future<FilmRollResponse> Function(int)? getFilmRoll,
    Future<VisitCreateResponse> Function(int, VisitCreateRequest)? createVisit,
    Future<PhotoUploadUrlResponse> Function(int, PhotoUploadUrlRequest)?
    requestPhotoUploadUrl,
    Future<PhotoCompleteResponse> Function(int, int)? completePhotoUpload,
    Future<FilmRollPhotoListResponse> Function(int)? getFilmRollPhotos,
    PutPhotoToS3? putPhotoToS3,
    RegionCode? Function()? currentRegion,
  }) {
    return FilmRollSyncService(
      filmRollRepository: repository,
      filmRollPlaceRepository: placeRepository,
      photoRepository: photoRepository,
      preferences: prefs,
      createFilmRoll: createFilmRoll ?? (_) async => _fakeResponse(),
      getFilmRoll: getFilmRoll ?? (id) async => _fakeResponse(id: id),
      createVisit: createVisit ?? (_, __) async => VisitCreateResponse.empty(),
      requestPhotoUploadUrl:
          requestPhotoUploadUrl ??
          (_, req) async => _uploadUrlResponse(
            photoId: 500 + req.sequence,
            sequence: req.sequence,
          ),
      completePhotoUpload:
          completePhotoUpload ??
          (_, photoId) async => _completeResponse(photoId: photoId),
      getFilmRollPhotos:
          getFilmRollPhotos ?? (_) async => FilmRollPhotoListResponse.empty(),
      putPhotoToS3:
          putPhotoToS3 ??
          ({
            required uploadUrl,
            required bytes,
            required requiredHeaders,
          }) async {},
      readPhotoBytes: (_) async => Uint8List.fromList([1, 2, 3]),
      // seedFilmRoll이 공주 필름롤을 만드므로, 기본 현재 지역도 공주로 둔다.
      currentRegion: currentRegion ?? () => RegionCode.gongju,
    );
  }

  group('생성', () {
    test('serverFilmRollId가 없으면 생성하고 clientFilmRollId를 멱등키로 보낸다', () async {
      final fr = await seedFilmRoll();
      var calls = 0;
      FilmRollCreateRequest? sent;

      final result = await service(
        createFilmRoll: (req) async {
          calls++;
          sent = req;
          return _fakeResponse(id: 900);
        },
      ).syncFilmRoll(fr.id);

      expect(calls, 1);
      expect(sent!.clientFilmRollId, fr.id);
      expect(sent!.toJson()['clientFilmRollId'], fr.id);
      expect(result.created, isTrue);
      expect((await repository.findById(fr.id))!.serverFilmRollId, 900);
    });

    test('serverFilmRollId가 이미 있으면 생성하지 않는다', () async {
      final fr = await seedFilmRoll();
      await repository.linkServerFilmRoll(
        clientFilmRollId: fr.id,
        serverFilmRollId: 555,
      );
      var calls = 0;

      final result = await service(
        createFilmRoll: (_) async {
          calls++;
          return _fakeResponse();
        },
      ).syncFilmRoll(fr.id);

      expect(calls, 0);
      expect(result.created, isFalse);
    });

    test('멱등 재요청: 서버가 기존 롤을 반환하면 그 id를 저장한다', () async {
      final fr = await seedFilmRoll();

      await service(
        createFilmRoll: (_) async => _fakeResponse(id: 555),
      ).syncFilmRoll(fr.id);

      expect((await repository.findById(fr.id))!.serverFilmRollId, 555);
    });

    test('현재 계정을 알 수 없으면 아무 API도 호출하지 않는다', () async {
      final fr = await seedFilmRoll();
      await prefs.setCurrentUserId(null);
      var calls = 0;

      final result = await service(
        createFilmRoll: (_) async {
          calls++;
          return _fakeResponse();
        },
      ).syncFilmRoll(fr.id);

      expect(calls, 0);
      expect(result.created, isFalse);
    });

    test('filterId를 필름롤 지역 코드로 보낸다 (regionId와 일치)', () async {
      final fr = await repository.findOrCreateActiveByRegion(
        regionCode: RegionCode.yesan,
        regionName: '예산군',
        regionId: 4,
      );
      FilmRollCreateRequest? sent;

      await service(
        currentRegion: () => RegionCode.yesan,
        createFilmRoll: (req) async {
          sent = req;
          return _fakeResponse();
        },
      ).syncFilmRoll(fr.id);

      expect(sent!.regionId, 4);
      expect(sent!.filterId, 'yesan');
      expect(sent!.toJson()['filterId'], 'yesan');
    });

    test('생성 중 네트워크 5xx 오류는 예외를 던지지 않고 result.error에 담긴다', () async {
      final fr = await seedFilmRoll();

      final result = await service(
        createFilmRoll: (_) async => throw _dioError(500),
      ).syncFilmRoll(fr.id);

      expect(result.hasError, isTrue);
      expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
    });

    test('다른 CAPTURING 롤 존재로 4xx 거절되면 미연동·무오류 보류', () async {
      final fr = await seedFilmRoll();

      final result = await service(
        createFilmRoll: (_) async =>
            throw _dioError(409, message: '이탈하지 않은 필름롤이 있습니다'),
      ).syncFilmRoll(fr.id);

      expect(result.hasError, isFalse);
      expect(result.created, isFalse);
      expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
    });
  });

  group('방문 전송', () {
    Future<FilmRoll> seedLinkedWithPlaces() async {
      final fr = await seedFilmRoll();
      await repository.linkServerFilmRoll(
        clientFilmRollId: fr.id,
        serverFilmRollId: 900,
      );
      await repository.selectCourse(
        filmRollId: fr.id,
        courseId: 'c1',
        courseTitle: '코스',
        places: const [
          CourseCandidatePlace(
            name: 'A',
            address: 'a',
            category: 'cat',
            latitude: 36,
            longitude: 126,
            visitOrder: 0,
            serverPlaceId: 1,
          ),
          CourseCandidatePlace(
            name: 'B',
            address: 'b',
            category: 'cat',
            latitude: 36,
            longitude: 126,
            visitOrder: 1,
          ),
          CourseCandidatePlace(
            name: 'C',
            address: 'c',
            category: 'cat',
            latitude: 36,
            longitude: 126,
            visitOrder: 2,
            serverPlaceId: 3,
          ),
        ],
      );
      return fr;
    }

    test('방문했고 serverPlaceId·업로드된 사진이 있는 장소만 전송한다', () async {
      final fr = await seedLinkedWithPlaces();
      final places = await placeRepository.findByFilmRoll(fr.id);
      final a = places.firstWhere((p) => p.name == 'A');
      final b = places.firstWhere((p) => p.name == 'B');
      await seedPhoto(fr.id, a.id, sequence: 1);
      await seedPhoto(fr.id, b.id, sequence: 2);
      await placeRepository.markVisited(a.id); // serverPlaceId=1
      await placeRepository.markVisited(b.id); // serverPlaceId=null

      final visitCalls = <VisitCreateRequest>[];
      final result = await service(
        createVisit: (filmRollId, req) async {
          visitCalls.add(req);
          return VisitCreateResponse.empty();
        },
      ).syncFilmRoll(fr.id);

      expect(visitCalls.map((r) => r.placeId), [1]);
      // 방문에 업로드된 서버 photoId가 함께 실린다(sequence 1 → 501).
      expect(visitCalls.single.photoId, 501);
      expect(result.visitsPushed, 1);
      expect(result.visitsSkipped, 1);
      final after = await placeRepository.findByFilmRoll(fr.id);
      expect(after.firstWhere((p) => p.name == 'A').visitSyncedAt, isNotNull);
      expect(after.firstWhere((p) => p.name == 'B').visitSyncedAt, isNull);
    });

    test('업로드된 사진이 없으면 방문을 보류한다(visitsSkipped)', () async {
      final fr = await seedLinkedWithPlaces();
      final places = await placeRepository.findByFilmRoll(fr.id);
      final a = places.firstWhere((p) => p.name == 'A');
      await placeRepository.markVisited(a.id); // serverPlaceId=1, 사진 없음

      var visitCalls = 0;
      final result = await service(
        createVisit: (_, __) async {
          visitCalls++;
          return VisitCreateResponse.empty();
        },
      ).syncFilmRoll(fr.id);

      expect(visitCalls, 0);
      expect(result.visitsPushed, 0);
      expect(result.visitsSkipped, 1);
      expect(result.hasError, isFalse);
    });

    test('이미 방문함(409) 응답도 synced로 처리한다', () async {
      final fr = await seedLinkedWithPlaces();
      final places = await placeRepository.findByFilmRoll(fr.id);
      final a = places.firstWhere((p) => p.name == 'A');
      await seedPhoto(fr.id, a.id, sequence: 1);
      await placeRepository.markVisited(a.id);

      final result = await service(
        createVisit: (_, __) async =>
            throw _dioError(409, message: '이미 인증된 장소'),
      ).syncFilmRoll(fr.id);

      expect(result.visitsPushed, 1);
      final after = await placeRepository.findByFilmRoll(fr.id);
      expect(after.firstWhere((p) => p.name == 'A').visitSyncedAt, isNotNull);
    });

    test(
      '방문 인증이 photoId 필수(400)로 거부되면 오류가 아니라 skip으로 처리하고 미동기화로 남긴다',
      () async {
        final fr = await seedLinkedWithPlaces();
        final places = await placeRepository.findByFilmRoll(fr.id);
        await placeRepository.markVisited(
          places.firstWhere((p) => p.name == 'A').id,
        ); // serverPlaceId=1

        final result = await service(
          createVisit: (_, __) async => throw _dioError(
            400,
            message: '요청값이 올바르지 않습니다.',
            code: 'COMMON_001',
            fields: ['photoId'],
          ),
        ).syncFilmRoll(fr.id);

        expect(result.visitsPushed, 0);
        expect(result.visitsSkipped, 1);
        expect(result.hasError, isFalse);
        final after = await placeRepository.findByFilmRoll(fr.id);
        expect(after.firstWhere((p) => p.name == 'A').visitSyncedAt, isNull);
      },
    );

    test('방문 전송 중 5xx는 해당 장소만 미동기화로 남기고 계속 진행', () async {
      final fr = await seedLinkedWithPlaces();
      final places = await placeRepository.findByFilmRoll(fr.id);
      final a = places.firstWhere((p) => p.name == 'A');
      final c = places.firstWhere((p) => p.name == 'C');
      await seedPhoto(fr.id, a.id, sequence: 1);
      await seedPhoto(fr.id, c.id, sequence: 2);
      await placeRepository.markVisited(a.id); // serverPlaceId=1
      await placeRepository.markVisited(c.id); // serverPlaceId=3

      final result = await service(
        createVisit: (filmRollId, req) async {
          if (req.placeId == 1) throw _dioError(500);
          return VisitCreateResponse.empty();
        },
      ).syncFilmRoll(fr.id);

      expect(result.visitsPushed, 1);
      expect(result.hasError, isTrue);
      final after = await placeRepository.findByFilmRoll(fr.id);
      expect(after.firstWhere((p) => p.name == 'A').visitSyncedAt, isNull);
      expect(after.firstWhere((p) => p.name == 'C').visitSyncedAt, isNotNull);
    });
  });

  group('사진 업로드', () {
    Future<FilmRoll> seedLinkedWithOnePlace() async {
      final fr = await seedFilmRoll();
      await repository.linkServerFilmRoll(
        clientFilmRollId: fr.id,
        serverFilmRollId: 900,
      );
      await repository.selectCourse(
        filmRollId: fr.id,
        courseId: 'c1',
        courseTitle: '코스',
        places: const [
          CourseCandidatePlace(
            name: 'A',
            address: 'a',
            category: 'cat',
            latitude: 36,
            longitude: 126,
            visitOrder: 0,
            serverPlaceId: 1,
          ),
        ],
      );
      return fr;
    }

    Future<int?> serverPhotoIdOf(String filmRollId) async {
      final photos = await database.select(database.photos).get();
      return photos.firstWhere((p) => p.filmRollId == filmRollId).serverPhotoId;
    }

    test('미업로드 사진을 upload-url→PUT→complete로 올리고 serverPhotoId를 저장한다', () async {
      final fr = await seedLinkedWithOnePlace();
      final a = (await placeRepository.findByFilmRoll(fr.id)).single;
      await seedPhoto(fr.id, a.id, sequence: 1);

      var puts = 0;
      var completes = 0;
      final result = await service(
        putPhotoToS3:
            ({
              required uploadUrl,
              required bytes,
              required requiredHeaders,
            }) async => puts++,
        completePhotoUpload: (_, photoId) async {
          completes++;
          return _completeResponse(photoId: photoId);
        },
      ).syncFilmRoll(fr.id);

      expect(puts, 1);
      expect(completes, 1);
      expect(result.photosPushed, 1);
      expect(await serverPhotoIdOf(fr.id), 501);
    });

    test('업로드 요청이 sequence·contentLength·contentType을 담아 보낸다', () async {
      final fr = await seedLinkedWithOnePlace();
      final a = (await placeRepository.findByFilmRoll(fr.id)).single;
      await seedPhoto(fr.id, a.id, sequence: 1);

      PhotoUploadUrlRequest? sent;
      await service(
        requestPhotoUploadUrl: (_, req) async {
          sent = req;
          return _uploadUrlResponse(photoId: 777, sequence: req.sequence);
        },
      ).syncFilmRoll(fr.id);

      expect(sent!.sequence, 1);
      expect(sent!.contentType, 'image/jpeg');
      expect(sent!.contentLength, 3); // readPhotoBytes 스텁이 3바이트
    });

    test('S3 미설정(404)이면 오류 없이 건너뛴다', () async {
      final fr = await seedLinkedWithOnePlace();
      final a = (await placeRepository.findByFilmRoll(fr.id)).single;
      await seedPhoto(fr.id, a.id, sequence: 1);

      final result = await service(
        requestPhotoUploadUrl: (_, __) async =>
            throw _dioError(404, code: 'FILM_ROLL_NOT_FOUND'),
      ).syncFilmRoll(fr.id);

      expect(result.photosSkipped, 1);
      expect(result.photosPushed, 0);
      expect(result.hasError, isFalse);
      expect(await serverPhotoIdOf(fr.id), isNull);
    });

    test(
      '이미 UPLOADED(409)면 GET /photos에서 같은 sequence의 photoId를 복구한다',
      () async {
        final fr = await seedLinkedWithOnePlace();
        final a = (await placeRepository.findByFilmRoll(fr.id)).single;
        await seedPhoto(fr.id, a.id, sequence: 1);

        final result = await service(
          requestPhotoUploadUrl: (_, __) async =>
              throw _dioError(409, code: 'PHOTO_SEQUENCE_ALREADY_IN_USE'),
          getFilmRollPhotos: (_) async => FilmRollPhotoListResponse(
            filmRollId: 900,
            filmRollStatus: 'CAPTURING',
            totalPhotoCount: 1,
            photos: [_serverPhoto(photoId: 909, sequence: 1)],
          ),
        ).syncFilmRoll(fr.id);

        expect(result.photosPushed, 1);
        expect(await serverPhotoIdOf(fr.id), 909);
      },
    );

    test('업로드 중 5xx는 result.error에 담긴다', () async {
      final fr = await seedLinkedWithOnePlace();
      final a = (await placeRepository.findByFilmRoll(fr.id)).single;
      await seedPhoto(fr.id, a.id, sequence: 1);

      final result = await service(
        requestPhotoUploadUrl: (_, __) async => throw _dioError(500),
      ).syncFilmRoll(fr.id);

      expect(result.hasError, isTrue);
      expect(await serverPhotoIdOf(fr.id), isNull);
    });

    test('이미 업로드된 사진은 다시 올리지 않는다', () async {
      final fr = await seedLinkedWithOnePlace();
      final a = (await placeRepository.findByFilmRoll(fr.id)).single;
      await seedPhoto(fr.id, a.id, sequence: 1);
      await photoRepository.markUploaded('photo-${fr.id}-1', serverPhotoId: 42);

      var urlCalls = 0;
      final result = await service(
        requestPhotoUploadUrl: (_, req) async {
          urlCalls++;
          return _uploadUrlResponse(photoId: 1, sequence: req.sequence);
        },
      ).syncFilmRoll(fr.id);

      expect(urlCalls, 0);
      expect(result.photosPushed, 0);
    });
  });

  group('status 미러링', () {
    test('동기화 끝에 서버 status를 조회해 로컬에 저장한다', () async {
      final fr = await seedFilmRoll();
      await repository.linkServerFilmRoll(
        clientFilmRollId: fr.id,
        serverFilmRollId: 900,
      );

      final result = await service(
        getFilmRoll: (id) async => _fakeResponse(id: id, status: 'READY'),
      ).syncFilmRoll(fr.id);

      expect(result.serverStatus, 'READY');
      expect((await repository.findById(fr.id))!.serverStatus, 'READY');
    });

    test('status 조회 실패는 전체 결과를 실패로 만들지 않는다', () async {
      final fr = await seedFilmRoll();
      await repository.linkServerFilmRoll(
        clientFilmRollId: fr.id,
        serverFilmRollId: 900,
      );

      final result = await service(
        getFilmRoll: (_) async => throw _dioError(503),
      ).syncFilmRoll(fr.id);

      expect(result.serverStatus, isNull);
      expect(result.hasError, isFalse);
    });
  });

  group('현재 위치 지역 가드', () {
    test('현재 지역이 필름롤 지역과 다르면 아무 API도 호출하지 않는다', () async {
      final fr = await seedFilmRoll(); // 공주 필름롤
      var createCalls = 0;

      final result = await service(
        currentRegion: () => RegionCode.yesan, // 사용자는 예산에 있음
        createFilmRoll: (_) async {
          createCalls++;
          return _fakeResponse();
        },
      ).syncFilmRoll(fr.id);

      expect(createCalls, 0);
      expect(result.created, isFalse);
      expect(result.hasError, isFalse);
      expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
    });

    test('위치 인증 이력이 없으면(currentRegion null) 동기화를 보류한다', () async {
      final fr = await seedFilmRoll();
      var createCalls = 0;

      await service(
        currentRegion: () => null,
        createFilmRoll: (_) async {
          createCalls++;
          return _fakeResponse();
        },
      ).syncFilmRoll(fr.id);

      expect(createCalls, 0);
      expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
    });

    test('현재 지역이 필름롤 지역과 같으면 정상 동기화한다', () async {
      final fr = await seedFilmRoll();

      final result = await service(
        currentRegion: () => RegionCode.gongju,
      ).syncFilmRoll(fr.id);

      expect(result.created, isTrue);
      expect((await repository.findById(fr.id))!.serverFilmRollId, 900);
    });

    test('skipRegionCheck가 true면 지역이 달라도 동기화한다(지역 이탈 확정용)', () async {
      final fr = await seedFilmRoll(); // 공주 필름롤

      final result = await service(
        currentRegion: () => RegionCode.yesan, // 이미 지역을 벗어난 상태
      ).syncFilmRoll(fr.id, skipRegionCheck: true);

      expect(result.created, isTrue);
      expect((await repository.findById(fr.id))!.serverFilmRollId, 900);
    });
  });
}
