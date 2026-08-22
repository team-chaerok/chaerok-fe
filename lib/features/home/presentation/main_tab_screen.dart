import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/explore/presentation/explore_screen.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_collection_screen.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_screen.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:chaerok/features/settings/presentation/my_screen.dart';
import 'package:flutter/material.dart';

/// 로그인 이후 진입하는 5탭(홈/채록길/카메라/필름/마이) 하단 네비게이션 셸.
/// 카메라는 탭 전환이 아니라 즉시 액션이므로 [HomeBottomNavigation]의
/// `onCameraTap` 콜백으로 별도 처리하고, IndexedStack은 나머지 4탭만 갖는다.
class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  static const _tag = 'MainTabScreen';

  int _selectedIndex = 0;
  bool _isResolvingCameraEntry = false;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onExploreRequested() {
    setState(() => _selectedIndex = 1);
  }

  /// 카메라 액션: 진행중 필름롤이 있으면 다음 미방문 장소 촬영으로 바로 진입하고,
  /// 없으면 "지역 선택하기"/"자유 촬영하기" 선택지를 보여준다.
  Future<void> _onCameraTap() async {
    if (_isResolvingCameraEntry) return;
    setState(() => _isResolvingCameraEntry = true);

    try {
      final recovered = await FilmRollModule.instance
          .recoverLastActiveFilmRoll();
      if (!mounted) return;

      if (recovered == null) {
        await _showNoActiveFilmRollSheet();
        return;
      }

      final places = await FilmRollModule.instance.filmRollPlaceRepository
          .findByFilmRoll(recovered.id);
      if (!mounted) return;

      FilmRollPlace? nextPlace;
      for (final place in places) {
        if (!place.isVisited) {
          nextPlace = place;
          break;
        }
      }

      if (nextPlace == null) {
        // 코스 미선택 또는 전체 방문 완료 - 필름롤 상세에서 다음 행동을 안내한다.
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FilmRollScreen(filmRollId: recovered.id),
          ),
        );
        return;
      }

      final captured = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VisitCaptureScreen(
            filmRollId: recovered.id,
            filmRollPlaceId: nextPlace!.id,
          ),
        ),
      );
      if (captured == true) {
        try {
          await FilmRollModule.instance.completeVisit(nextPlace.id);
        } catch (e, st) {
          log('방문 완료 처리 실패', name: _tag, error: e, stackTrace: st);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('촬영은 완료됐지만 방문 처리에 실패했어요.')),
          );
        }
      }
    } catch (e, st) {
      log('카메라 진입 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카메라를 여는 중 문제가 발생했어요.')));
    } finally {
      if (mounted) setState(() => _isResolvingCameraEntry = false);
    }
  }

  Future<void> _showNoActiveFilmRollSheet() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChaerokColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChaerokRadius.lg),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.lg,
                    vertical: ChaerokSpacing.xs,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '진행중인 필름롤이 없어요',
                      style: ChaerokTypography.labelLarge,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.explore_outlined),
                  title: const Text('지역 선택하기'),
                  subtitle: const Text('채록길에서 지역을 고르고 필름롤을 시작해요'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _onExploreRequested();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('자유 촬영하기'),
                  subtitle: const Text('곧 만나볼 수 있어요'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('자유 촬영하기는 준비 중이에요.')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeDashboardScreen(),
          ExploreScreen(),
          FilmRollCollectionScreen(),
          MyScreen(),
        ],
      ),
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemSelected: _onTabSelected,
        onCameraTap: _onCameraTap,
      ),
    );
  }
}
