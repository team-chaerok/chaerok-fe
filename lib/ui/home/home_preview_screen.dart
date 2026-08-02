import 'package:chaerok/features/home/presentation/widgets/active_film_roll_card.dart';
import 'package:chaerok/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:chaerok/features/home/presentation/widgets/place_category_menu.dart';
import 'package:chaerok/features/home/presentation/widgets/recommended_place_card.dart';
import 'package:chaerok/ui/home/models/home_preview_data.dart';
import 'package:chaerok/ui/preview_theme.dart';
import 'package:flutter/material.dart';

class HomePreviewScreen extends StatefulWidget {
  const HomePreviewScreen({super.key, this.data = HomePreviewData.sample});

  final HomePreviewData data;

  @override
  State<HomePreviewScreen> createState() => _HomePreviewScreenState();
}

class _HomePreviewScreenState extends State<HomePreviewScreen> {
  static const _navigationFeedback = [
    '현재 홈 화면이에요.',
    '채록길 화면은 UI 확정 후 연결할 예정이에요.',
    '필름 화면은 UI 확정 후 연결할 예정이에요.',
    '마이 화면은 UI 확정 후 연결할 예정이에요.',
  ];

  int _selectedCategoryIndex = 0;

  void _showPreviewMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: UiPreviewColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiPreviewRadius.md),
          ),
          content: Text(
            message,
            style: UiPreviewTypography.bodyMedium.copyWith(
              color: UiPreviewColors.surface,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.data.recommendedPlaces;

    return Scaffold(
      backgroundColor: UiPreviewColors.background,
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: 0,
        onItemSelected: (index) {
          _showPreviewMessage(_navigationFeedback[index]);
        },
        onCameraTap: () {
          _showPreviewMessage('카메라 화면은 다음 단계에서 새롭게 연결할 예정이에요.');
        },
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                UiPreviewSpacing.lg,
                UiPreviewSpacing.xs,
                UiPreviewSpacing.lg,
                UiPreviewSpacing.xl,
              ),
              sliver: SliverList.list(
                children: [
                  _HomeHeader(
                    regionName: widget.data.regionName,
                    userNickname: widget.data.userNickname,
                    onNotificationTap: () {
                      _showPreviewMessage('새로운 알림이 없어요.');
                    },
                  ),
                  const SizedBox(height: UiPreviewSpacing.sm),
                  ActiveFilmRollCard(data: widget.data.filmRoll),
                  const SizedBox(height: UiPreviewSpacing.xl),
                  const _SectionHeader(),
                  const SizedBox(height: UiPreviewSpacing.sm),
                  PlaceCategoryMenu(
                    selectedIndex: _selectedCategoryIndex,
                    onSelected: (index) {
                      setState(() => _selectedCategoryIndex = index);
                    },
                  ),
                  const SizedBox(height: UiPreviewSpacing.sm),
                  if (places.isNotEmpty) ...[
                    RecommendedPlaceCard(
                      data: places.first,
                      isFeatured: true,
                      onTap: () {
                        _showPreviewMessage(
                          '${places.first.name}을(를) 자유롭게 둘러볼 수 있어요.',
                        );
                      },
                    ),
                    ...places
                        .skip(1)
                        .map(
                          (place) => Padding(
                            padding: const EdgeInsets.only(
                              top: UiPreviewSpacing.sm,
                            ),
                            child: RecommendedPlaceCard(
                              data: place,
                              onTap: () {
                                _showPreviewMessage(
                                  '${place.name}을(를) 자유롭게 둘러볼 수 있어요.',
                                );
                              },
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.regionName,
    required this.userNickname,
    required this.onNotificationTap,
  });

  final String regionName;
  final String userNickname;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: Row(
            children: [
              Text(
                '안녕하세요, $userNickname님',
                style: UiPreviewTypography.bodyMedium.copyWith(
                  color: UiPreviewColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '알림',
                onPressed: onNotificationTap,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.notifications_none_rounded, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: UiPreviewSpacing.xs),
        const Text('현재 지역', style: UiPreviewTypography.labelSmall),
        const SizedBox(height: UiPreviewSpacing.xxs / 2),
        Text(
          regionName,
          style: UiPreviewTypography.displayMedium.copyWith(
            fontFamily: UiPreviewTypography.jeongnimsajiFontFamily,
            fontSize: 23,
            height: 1.15,
            letterSpacing: -0.2,
            color: UiPreviewColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('주변 추천 장소', style: UiPreviewTypography.headingLarge),
              SizedBox(height: UiPreviewSpacing.xxs),
              Text(
                '마음이 가는 장소를 자유롭게 골라보세요.',
                style: UiPreviewTypography.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
