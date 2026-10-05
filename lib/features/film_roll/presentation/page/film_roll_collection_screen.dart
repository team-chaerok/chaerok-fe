import 'dart:async';
import 'dart:developer';

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
  });

  /// 홈 폴더 카드처럼 이미 상위 화면이 헤더를 가진 곳에 끼워 넣을 때 false.
  final bool showAppBar;

  /// 테스트에서 실제 로컬 DB 조회 대신 필름롤 목록을 주입하기 위한 훅.
  @visibleForTesting
  final Future<List<FilmRoll>> Function()? debugFetchFilmRolls;

  /// 테스트에서 실제 삭제 유스케이스 호출 대신 결과를 주입하기 위한 훅.
  @visibleForTesting
  final Future<void> Function(String filmRollId)? debugDeleteFilmRoll;

  @override
  State<FilmRollCollectionScreen> createState() =>
      _FilmRollCollectionScreenState();
}

class _FilmRollCollectionScreenState extends State<FilmRollCollectionScreen> {
  static const _tag = 'FilmRollCollectionScreen';

  bool _isLoading = true;
  String? _errorMessage;
  List<FilmRoll> _filmRolls = const [];

  /// 삭제 확인/삭제 API 호출이 진행 중인 필름롤 id. 중복 탭 방지용.
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    unawaited(_fetch());
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
      if (!mounted) return;
      setState(() {
        _filmRolls = filmRolls;
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
        padding: const EdgeInsets.all(ChaerokSpacing.lg),
        decoration: BoxDecoration(
          color: ChaerokColors.surface,
          borderRadius: BorderRadius.circular(ChaerokRadius.md),
          border: Border.all(color: ChaerokColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(filmRoll.title, style: ChaerokTypography.titleMedium),
                  const SizedBox(height: ChaerokSpacing.xxs),
                  Text(
                    _statusLabel(filmRoll),
                    style: ChaerokTypography.bodyMedium.copyWith(
                      color: ChaerokColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(_statusIcon(filmRoll), color: _statusIconColor(filmRoll)),
            const SizedBox(width: ChaerokSpacing.xs),
            _buildDeleteButton(filmRoll, isDeleting: isDeleting),
          ],
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
      icon: const Icon(Icons.close, color: ChaerokColors.textSecondary),
      iconSize: 20,
      tooltip: '필름롤 삭제',
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      padding: EdgeInsets.zero,
    );
  }

  String _statusLabel(FilmRoll filmRoll) {
    return switch (filmRoll.status) {
      FilmRollStatus.completed => '완료 · ${filmRoll.visitedPlaceCount}곳 방문',
      FilmRollStatus.developing => '현상 중 · 완료까지 대기 중',
      FilmRollStatus.expired => '만료 · 현상 조건 미충족',
      FilmRollStatus.inProgress =>
        '${filmRoll.visitedPlaceCount} / ${filmRoll.totalPlaceCount}곳 방문',
    };
  }

  IconData _statusIcon(FilmRoll filmRoll) {
    return switch (filmRoll.status) {
      FilmRollStatus.completed => Icons.check_circle,
      FilmRollStatus.developing => Icons.hourglass_bottom,
      FilmRollStatus.expired => Icons.cancel_outlined,
      FilmRollStatus.inProgress => Icons.chevron_right,
    };
  }

  Color _statusIconColor(FilmRoll filmRoll) {
    return switch (filmRoll.status) {
      FilmRollStatus.completed ||
      FilmRollStatus.developing => ChaerokColors.primary,
      FilmRollStatus.expired ||
      FilmRollStatus.inProgress => ChaerokColors.textSecondary,
    };
  }
}
