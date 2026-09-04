import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

/// 진행중/완료 필름롤을 모아 보여주는 컬렉션 화면.
class FilmRollCollectionScreen extends StatefulWidget {
  const FilmRollCollectionScreen({super.key});

  @override
  State<FilmRollCollectionScreen> createState() =>
      _FilmRollCollectionScreenState();
}

class _FilmRollCollectionScreenState extends State<FilmRollCollectionScreen> {
  static const _tag = 'FilmRollCollectionScreen';

  bool _isLoading = true;
  String? _errorMessage;
  List<FilmRoll> _filmRolls = const [];

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
      final filmRolls = await FilmRollModule.instance.filmRollRepository
          .findAll();
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
        builder: (_) => FilmRollScreen(filmRollId: filmRoll.id),
      ),
    );
    if (!mounted) return;
    await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('필름 컬렉션', style: ChaerokTypography.titleMedium),
      ),
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
          ],
        ),
      ),
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
