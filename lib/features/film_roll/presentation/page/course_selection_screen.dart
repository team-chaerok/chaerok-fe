import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/remote/courses_api.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

/// 지역의 추천 코스 후보를 조회해 사용자가 하나를 선택하도록 하는 화면.
/// 선택된 [CourseResponse]는 확정 저장 없이 `Navigator.pop`으로 반환되며,
/// 실제 로컬 DB 저장은 호출부(FilmRollScreen)의 코스 확정 처리에서 이뤄진다.
class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key, required this.regionId});

  final int regionId;

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  static const _tag = 'CourseSelectionScreen';

  bool _isLoading = true;
  String? _errorMessage;
  List<CourseResponse> _courses = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_fetchCourses());
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await CoursesApi.getRecommendedCourses(widget.regionId);
      if (!mounted) return;
      setState(() {
        _courses = response.courses;
        _isLoading = false;
      });
    } catch (e, st) {
      log('추천 코스 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _onCourseSelected(CourseResponse course) {
    Navigator.of(context).pop(course);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('코스 선택', style: ChaerokTypography.titleMedium),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.xxl,
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.error,
                ),
              ),
            ),
            const SizedBox(height: ChaerokSpacing.sm),
            TextButton(onPressed: _fetchCourses, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Text('추천 코스가 없어요', style: ChaerokTypography.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      itemCount: _courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: ChaerokSpacing.sm),
      itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
    );
  }

  Widget _buildCourseCard(CourseResponse course) {
    return InkWell(
      onTap: () => _onCourseSelected(course),
      borderRadius: BorderRadius.circular(ChaerokRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(ChaerokSpacing.lg),
        decoration: BoxDecoration(
          color: ChaerokColors.surface,
          borderRadius: BorderRadius.circular(ChaerokRadius.md),
          border: Border.all(color: ChaerokColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.title, style: ChaerokTypography.titleMedium),
            const SizedBox(height: ChaerokSpacing.xxs),
            Text(
              '장소 ${course.places.length}곳',
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.textSecondary,
              ),
            ),
            const SizedBox(height: ChaerokSpacing.xs),
            ...course.places.map(
              (place) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '· ${place.title}',
                  style: ChaerokTypography.caption.copyWith(
                    color: ChaerokColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
