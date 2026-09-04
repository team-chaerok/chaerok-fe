import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_place_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/photo_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/complete_visit_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/delete_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/delete_photo_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/enter_region_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/exit_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/get_film_roll_photo_count_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/recover_last_active_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/save_photo_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/select_course_use_case.dart';

/// 필름롤 기능의 리포지토리/유스케이스 인스턴스를 조립하는 단순 조립 지점.
/// 프로젝트에 별도 DI 프레임워크가 없으므로, 기존 `TokenStorage.instance`/
/// `DioClient.instance`와 동일한 지연 초기화 싱글턴 패턴을 따른다.
class FilmRollModule {
  FilmRollModule._()
    : filmRollRepository = FilmRollRepositoryImpl(
        database: AppDatabase.instance,
        filmRollDataSource: FilmRollLocalDataSource(AppDatabase.instance),
        placeDataSource: FilmRollPlaceLocalDataSource(AppDatabase.instance),
        photoDataSource: PhotoLocalDataSource(AppDatabase.instance),
        photoStorage: LocalPhotoStorage.instance,
      ),
      filmRollPlaceRepository = FilmRollPlaceRepositoryImpl(
        placeDataSource: FilmRollPlaceLocalDataSource(AppDatabase.instance),
        photoDataSource: PhotoLocalDataSource(AppDatabase.instance),
      ),
      photoRepository = PhotoRepositoryImpl(
        photoDataSource: PhotoLocalDataSource(AppDatabase.instance),
        photoStorage: LocalPhotoStorage.instance,
      ) {
    filmRollSyncService = FilmRollSyncService(
      filmRollRepository: filmRollRepository,
      filmRollPlaceRepository: filmRollPlaceRepository,
    );
    enterRegion = EnterRegionUseCase(
      filmRollRepository: filmRollRepository,
      syncService: filmRollSyncService,
    );
    selectCourse = SelectCourseUseCase(filmRollRepository);
    completeVisit = CompleteVisitUseCase(filmRollPlaceRepository);
    savePhoto = SavePhotoUseCase(photoRepository);
    deletePhoto = DeletePhotoUseCase(photoRepository);
    getFilmRollPhotoCount = GetFilmRollPhotoCountUseCase(photoRepository);
    recoverLastActiveFilmRoll = RecoverLastActiveFilmRollUseCase(
      filmRollRepository: filmRollRepository,
    );
    deleteFilmRoll = DeleteFilmRollUseCase(
      filmRollRepository: filmRollRepository,
    );
    exitFilmRoll = ExitFilmRollUseCase(
      filmRollRepository: filmRollRepository,
      syncService: filmRollSyncService,
    );
  }

  static FilmRollModule? _instance;

  static FilmRollModule get instance => _instance ??= FilmRollModule._();

  final FilmRollRepository filmRollRepository;
  final FilmRollPlaceRepository filmRollPlaceRepository;
  final PhotoRepository photoRepository;

  /// 로컬 필름롤/방문을 백엔드에 반영하는 동기화 서비스.
  late final FilmRollSyncService filmRollSyncService;

  late final EnterRegionUseCase enterRegion;
  late final SelectCourseUseCase selectCourse;
  late final CompleteVisitUseCase completeVisit;
  late final SavePhotoUseCase savePhoto;
  late final DeletePhotoUseCase deletePhoto;
  late final GetFilmRollPhotoCountUseCase getFilmRollPhotoCount;
  late final RecoverLastActiveFilmRollUseCase recoverLastActiveFilmRoll;
  late final DeleteFilmRollUseCase deleteFilmRoll;
  late final ExitFilmRollUseCase exitFilmRoll;
}
