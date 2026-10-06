import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_screen.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

/// 진행중/완료 필름롤을 모아 보여주는 컬렉션 화면.
class FilmRollCollectionScreen extends StatefulWidget {
  const FilmRollCollectionScreen({
    super.key,
    this.showAppBar = true,
    @visibleForTesting this.debugFetchFilmRolls,
    @visibleForTesting this.debugDeleteFilmRoll,
    @visibleForTesting this.debugCountPhotos,
    @visibleForTesting this.debugFindCoverPhotoPath,
  });

  /// 홈 폴더 카드처럼 이미 상위 화면이 헤더를 가진 곳에 끼워 넣을 때 false.
  final bool showAppBar;

  /// 테스트에서 실제 로컬 DB 조회 대신 필름롤 목록을 주입하기 위한 훅.
  @visibleForTesting
  final Future<List<FilmRoll>> Function()? debugFetchFilmRolls;

  /// 테스트에서 실제 삭제 유스케이스 호출 대신 결과를 주입하기 위한 훅.
  @visibleForTesting
  final Future<void> Function(String filmRollId)? debugDeleteFilmRoll;

  /// 테스트에서 실제 로컬 DB 대신 필름롤별 사진 수를 주입하기 위한 훅.
  @visibleForTesting
  final Future<int> Function(String filmRollId)? debugCountPhotos;

  /// 테스트에서 실제 로컬 DB 대신 필름롤 대표 사진 경로를 주입하기 위한 훅.
  @visibleForTesting
  final Future<String?> Function(String filmRollId)? debugFindCoverPhotoPath;

  @override
  State<FilmRollCollectionScreen> createState() =>
      _FilmRollCollectionScreenState();
}

class _FilmRollCollectionScreenState extends State<FilmRollCollectionScreen> {
  static const _tag = 'FilmRollCollectionScreen';

  bool _isLoading = true;
  String? _errorMessage;
  List<FilmRoll> _filmRolls = const [];

  /// 필름롤 id별 촬영한 사진 수. 세지 못한 필름롤은 빠져 있고, 그 카드는 사진
  /// 수 없이 상태만 보여준다.
  Map<String, int> _photoCounts = const {};

  /// 필름롤 id별 대표 사진(가장 최근에 찍은 사진 썸네일) 경로. 사진이 없거나
  /// 읽지 못한 필름롤은 빠져 있고, 그 카드는 빈 필름 칸을 보여준다.
  Map<String, String> _coverPhotoPaths = const {};

  /// 삭제 확인/삭제 API 호출이 진행 중인 필름롤 id. 중복 탭 방지용.
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
  }

  /// 필름롤마다 기기에 저장된 사진 수를 센다. 일부를 세지 못해도 목록은
  /// 보여줘야 하므로 실패한 필름롤만 빼고 반환한다.
  Future<Map<String, int>> _countPhotos(List<FilmRoll> filmRolls) async {
    // 목록을 주입한 테스트에서는 실제 DB를 열지 않도록, 사진 수 훅이 없으면
    // 세지 않는다.
    final countPhotos =
        widget.debugCountPhotos ??
        (widget.debugFetchFilmRolls == null
            ? FilmRollModule.instance.getFilmRollPhotoCount.call
            : null);
    if (countPhotos == null) return const {};

    final entries = await Future.wait(
      filmRolls.map((filmRoll) async {
        try {
          return MapEntry(filmRoll.id, await countPhotos(filmRoll.id));
        } catch (e, st) {
          log('필름롤 사진 수 조회 실패', name: _tag, error: e, stackTrace: st);
          return null;
        }
      }),
    );
    return Map.fromEntries(entries.nonNulls);
  }

  /// 필름롤마다 가장 최근에 찍은 사진의 썸네일 경로를 찾는다. 실패한 필름롤은
  /// 빼고 반환한다(목록 표시는 막지 않는다).
  Future<Map<String, String>> _findCoverPhotoPaths(
    List<FilmRoll> filmRolls,
  ) async {
    final findCoverPhotoPath =
        widget.debugFindCoverPhotoPath ??
        (widget.debugFetchFilmRolls == null ? _findLatestThumbnailPath : null);
    if (findCoverPhotoPath == null) return const {};

    final entries = await Future.wait(
      filmRolls.map((filmRoll) async {
        try {
          final path = await findCoverPhotoPath(filmRoll.id);
          return path == null ? null : MapEntry(filmRoll.id, path);
        } catch (e, st) {
          log('필름롤 대표 사진 조회 실패', name: _tag, error: e, stackTrace: st);
          return null;
        }
      }),
    );
    return Map.fromEntries(entries.nonNulls);
  }

  static Future<String?> _findLatestThumbnailPath(String filmRollId) async {
    final photos = await FilmRollModule.instance.photoRepository.findByFilmRoll(
      filmRollId,
      limit: 1,
    );
    return photos.isEmpty ? null : photos.first.thumbnailPath;
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final override = widget.debugFetchFilmRolls;
      final filmRolls = override != null
          ? await override()
          : await FilmRollModule.instance.filmRollRepository.findAll();
      final (photoCounts, coverPhotoPaths) = await (
        _countPhotos(filmRolls),
        _findCoverPhotoPaths(filmRolls),
      ).wait;
      if (!mounted) return;
      setState(() {
        _filmRolls = filmRolls;
        _photoCounts = photoCounts;
        _coverPhotoPaths = coverPhotoPaths;
        _isLoading = false;
      });
    } catch (e, st) {
      log('필름롤 목록 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = '필름롤 목록을 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  Future<void> _onFilmRollTap(FilmRoll filmRoll) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => filmRoll.status == FilmRollStatus.completed
            ? FilmRollResultScreen(filmRoll: filmRoll)
            : FilmRollScreen(filmRollId: filmRoll.id),
      ),
    );
    if (!mounted) return;
    await _fetch();
  }

  Future<void> _onDeleteTap(FilmRoll filmRoll) async {
    if (_deletingIds.contains(filmRoll.id)) return;

    final confirmed = await _showDeleteConfirmDialog(context, filmRoll);
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _deletingIds.add(filmRoll.id));

    try {
      final override = widget.debugDeleteFilmRoll;
      if (override != null) {
        await override(filmRoll.id);
      } else {
        await FilmRollModule.instance.deleteFilmRoll(filmRoll.id);
      }
      if (!mounted) return;
      setState(() {
        _filmRolls = _filmRolls
            .where((roll) => roll.id != filmRoll.id)
            .toList();
        _deletingIds.remove(filmRoll.id);
      });
    } catch (e, st) {
      log('필름롤 삭제 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _deletingIds.remove(filmRoll.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필름롤을 삭제하지 못했어요.')));
    }
  }

  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    FilmRoll filmRoll,
  ) {
    final isCompleted = filmRoll.status == FilmRollStatus.completed;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('필름롤 삭제', style: ChaerokTypography.titleMedium),
        content: Text(
          isCompleted
              ? '${filmRoll.title}을(를) 삭제하면 저장된 필름 사진과 릴스도 함께 사라지며 복구할 수 없어요.'
              : '${filmRoll.title}을(를) 삭제하면 지금까지의 방문·촬영 기록도 함께 사라지며 복구할 수 없어요.',
          style: ChaerokTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: ChaerokColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: widget.showAppBar ? const ChaerokAppbar(title: '필름 컬렉션') : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: ChaerokLoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.error,
              ),
            ),
            const SizedBox(height: ChaerokSpacing.sm),
            TextButton(onPressed: _fetch, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_filmRolls.isEmpty) {
      return const Center(
        child: Text('아직 만든 필름롤이 없어요', style: ChaerokTypography.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      itemCount: _filmRolls.length,
      separatorBuilder: (_, __) => const SizedBox(height: ChaerokSpacing.sm),
      itemBuilder: (context, index) => _buildFilmRollCard(_filmRolls[index]),
    );
  }

  Widget _buildFilmRollCard(FilmRoll filmRoll) {
    final isDeleting = _deletingIds.contains(filmRoll.id);

    return InkWell(
      onTap: () => _onFilmRollTap(filmRoll),
      borderRadius: BorderRadius.circular(ChaerokRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ChaerokSpacing.sm),
        decoration: BoxDecoration(
          color: ChaerokColors.surface,
          borderRadius: BorderRadius.circular(ChaerokRadius.md),
          border: Border.all(color: ChaerokColors.border),
        ),
        child: Row(
          children: [
            _buildCoverPhoto(filmRoll),
            const SizedBox(width: ChaerokSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilmRollStatusChip(status: filmRoll.status),
                  const SizedBox(height: ChaerokSpacing.xxs),
                  Text(
                    filmRoll.title,
                    style: ChaerokTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _detailLabel(filmRoll),
                    style: ChaerokTypography.bodyMedium.copyWith(
                      color: ChaerokColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildDeleteButton(filmRoll, isDeleting: isDeleting),
          ],
        ),
      ),
    );
  }

  /// 카드 왼쪽의 대표 사진. 아직 찍은 사진이 없으면 빈 필름 칸을 보여준다.
  Widget _buildCoverPhoto(FilmRoll filmRoll) {
    const size = 72.0;
    final path = _coverPhotoPaths[filmRoll.id];
    const emptyFrame = ColoredBox(
      color: ChaerokColors.sageLight,
      child: Center(
        child: Icon(Icons.camera_roll_outlined, color: ChaerokColors.sageDark),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(ChaerokRadius.sm),
      child: SizedBox(
        width: size,
        height: size,
        child: path == null
            ? emptyFrame
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (context, error, stackTrace) => emptyFrame,
              ),
      ),
    );
  }

  /// 필름롤을 삭제하는 X 아이콘 버튼. 삭제가 진행 중이면 작은 로딩 인디케이터로
  /// 대체해 중복 탭을 막는다.
  Widget _buildDeleteButton(FilmRoll filmRoll, {required bool isDeleting}) {
    if (isDeleting) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Padding(
          padding: EdgeInsets.all(ChaerokSpacing.md),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ChaerokColors.textSecondary,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => _onDeleteTap(filmRoll),
      // 만료 상태 아이콘(Icons.cancel_outlined)과 혼동되지 않도록 휴지통
      // 모양으로 구분한다.
      icon: const Icon(
        Icons.delete_outline,
        color: ChaerokColors.textSecondary,
      ),
      iconSize: 20,
      tooltip: '필름롤 삭제',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }

  /// 상태 라벨 아래 줄에 보여줄 방문 현황과 사진 수.
  String _detailLabel(FilmRoll filmRoll) {
    final detail = switch (filmRoll.status) {
      FilmRollStatus.completed => '${filmRoll.visitedPlaceCount}곳 방문',
      FilmRollStatus.developing => '완료까지 대기 중',
      FilmRollStatus.expired => '현상 조건 미충족',
      FilmRollStatus.inProgress =>
        '${filmRoll.visitedPlaceCount} / ${filmRoll.totalPlaceCount}곳 방문',
    };
    final photoCount = _photoCounts[filmRoll.id];
    if (photoCount == null) return detail;
    return '$detail · 사진 $photoCount/${FilmRoll.maxExposureCount}';
  }
}

/// 필름롤 상태를 색으로 구분하는 작은 라벨. 새 색을 만들지 않고 디자인
/// 시스템 색에 투명도만 달리해 쓴다.
class _FilmRollStatusChip extends StatelessWidget {
  const _FilmRollStatusChip({required this.status});

  final FilmRollStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      FilmRollStatus.inProgress => (
        '진행 중',
        ChaerokColors.skyBlue,
        ChaerokColors.skyBlue.withValues(alpha: 0.14),
      ),
      FilmRollStatus.developing => (
        '현상 중',
        ChaerokColors.sageDark,
        ChaerokColors.primary.withValues(alpha: 0.28),
      ),
      FilmRollStatus.completed => (
        '완료',
        ChaerokColors.primaryDark,
        ChaerokColors.sageLight,
      ),
      FilmRollStatus.expired => (
        '만료',
        ChaerokColors.textSecondary,
        ChaerokColors.border,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChaerokSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(ChaerokRadius.full),
      ),
      child: Text(
        label,
        style: ChaerokTypography.caption.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
