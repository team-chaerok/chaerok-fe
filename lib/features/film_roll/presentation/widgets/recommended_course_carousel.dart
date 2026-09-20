import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:flutter/material.dart';

/// 추천 코스 후보를 가로로 넘겨 보는 카드 캐러셀.
///
/// 카드를 넘기면 [onPageChanged]로 인덱스가 전달되고, 장소 행을 탭하면
/// [onPlaceTap]으로 그 코스 안의 순번(1부터)이 전달된다. 카드는 코스를 훑어보는
/// 용도일 뿐 확정하지 않는다 — 확정은 호출부의 별도 버튼이 맡는다.
class RecommendedCourseCarousel extends StatefulWidget {
  const RecommendedCourseCarousel({
    super.key,
    required this.courses,
    required this.selectedIndex,
    required this.onPageChanged,
    required this.onPlaceTap,
    this.focusedPlaceOrder,
  });

  final List<CourseResponse> courses;
  final int selectedIndex;

  /// 선택된 코스에서 지도가 강조 중인 장소 순번(1부터). 없으면 null.
  final int? focusedPlaceOrder;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPlaceTap;

  static const double height = 176;

  @override
  State<RecommendedCourseCarousel> createState() =>
      _RecommendedCourseCarouselState();
}

class _RecommendedCourseCarouselState extends State<RecommendedCourseCarousel> {
  late final PageController _controller = PageController(
    initialPage: widget.selectedIndex,
    viewportFraction: 0.88,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RecommendedCourseCarousel.height,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.courses.length,
        onPageChanged: widget.onPageChanged,
        itemBuilder: (context, index) {
          final isSelected = index == widget.selectedIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.xxs),
            child: _CourseCard(
              course: widget.courses[index],
              position: index + 1,
              total: widget.courses.length,
              isSelected: isSelected,
              focusedPlaceOrder: isSelected ? widget.focusedPlaceOrder : null,
              onPlaceTap: widget.onPlaceTap,
            ),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.position,
    required this.total,
    required this.isSelected,
    required this.focusedPlaceOrder,
    required this.onPlaceTap,
  });

  final CourseResponse course;
  final int position;
  final int total;
  final bool isSelected;
  final int? focusedPlaceOrder;
  final ValueChanged<int> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        border: Border.all(
          color: isSelected ? ChaerokColors.primaryDark : ChaerokColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChaerokTypography.titleMedium,
                ),
              ),
              const SizedBox(width: ChaerokSpacing.xs),
              Text(
                '$position / $total',
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '장소 ${course.places.length}곳',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: course.places.length,
              itemBuilder: (context, index) => _PlaceRow(
                order: index + 1,
                title: course.places[index].title,
                isFocused: focusedPlaceOrder == index + 1,
                onTap: () => onPlaceTap(index + 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.order,
    required this.title,
    required this.isFocused,
    required this.onTap,
  });

  final int order;
  final String title;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChaerokRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFocused
                    ? ChaerokColors.primaryDark
                    : ChaerokColors.sageLight,
              ),
              child: Text(
                '$order',
                style: ChaerokTypography.caption.copyWith(
                  fontSize: 11,
                  color: isFocused ? Colors.white : ChaerokColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: ChaerokSpacing.xs),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.bodyMedium.copyWith(
                  fontWeight: isFocused ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
