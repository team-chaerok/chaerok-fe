import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_screen.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_category_menu.dart';
import 'package:chaerok/features/home/presentation/widgets/recommended_place_card.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

const _serviceProvinceName = '충청남도';

/// 채록길 탭: 4개 지원 지역(공주/부여/서산/예산) 중 하나를 골라 관광지를 둘러보고,
/// 필름롤을 시작하는 화면. 관광지 조회는 위치 인증 화면(`LocationVerificationScreen`)이
/// GPS 이후 수행하는 것과 동일한 지역 검증 → 외부 장소 조회 호출을 GPS 없이 재사용한다.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _tag = 'ExploreScreen';

  RegionCode _selectedRegion = RegionCode.gongju;
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  bool _isEnteringFilmRoll = false;
  String? _errorMessage;
  int? _regionId;
  List<PlaceListResponse> _places = const [];
  Position? _currentPosition;
  int _fetchRequestId = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentPosition());
    unawaited(_fetchPlaces());
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final position = await LocationPermissionService.getCurrentPosition();
      if (!mounted || position == null) return;
      setState(() => _currentPosition = position);
    } catch (e, st) {
      log('현재 위치 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _onRegionSelected(RegionCode region) async {
    if (region == _selectedRegion) return;
    setState(() => _selectedRegion = region);
    await _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final requestId = ++_fetchRequestId;
    final region = _selectedRegion;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolvedRegion = await RegionsApi.resolveRegion(
        ResolveRegionRequest(
          provinceName: _serviceProvinceName,
          cityCountyName: region.cityCountyName,
        ),
      );
      final places = await PlacesApi.getExternalPlaces(resolvedRegion.regionId);
      if (!mounted || requestId != _fetchRequestId) return;
      setState(() {
        _regionId = resolvedRegion.regionId;
        _places = places;
        _isLoading = false;
      });
    } catch (e, st) {
      log('관광지 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted || requestId != _fetchRequestId) return;
      setState(() {
        _errorMessage = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  /// 선택한 지역의 로컬 필름롤을 찾거나 새로 생성해 진입한다.
  Future<void> _onEnterRegionTap() async {
    if (_isEnteringFilmRoll) return;

    setState(() => _isEnteringFilmRoll = true);
    try {
      final filmRoll = await FilmRollModule.instance.enterRegion(
        _selectedRegion.cityCountyName,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              FilmRollScreen(filmRollId: filmRoll.id, regionId: _regionId),
        ),
      );
    } on UnsupportedRegionException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 필름롤을 지원하지 않는 지역이에요.')));
    } catch (e, st) {
      log('필름롤 진입 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필름롤을 불러오지 못했어요.')));
    } finally {
      if (mounted) setState(() => _isEnteringFilmRoll = false);
    }
  }

  String? _distanceLabel(PlaceListResponse place) {
    final position = _currentPosition;
    if (position == null) return null;

    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.latitude,
      place.longitude,
    );
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  RecommendedPlaceSummaryData _toSummaryData(
    PlaceListResponse place,
    int index,
  ) {
    const moods = PlacePlaceholderMood.values;
    return RecommendedPlaceSummaryData(
      name: place.title,
      category: place.categoryDetail,
      imageUrl: place.firstImageUrl,
      distance: _distanceLabel(place),
      placeholderMood: moods[index % moods.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('채록길', style: ChaerokTypography.titleMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ChaerokSpacing.md,
              ChaerokSpacing.sm,
              ChaerokSpacing.md,
              0,
            ),
            child: _buildRegionSelector(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            child: PlaceCategoryMenu(
              selectedIndex: _selectedCategoryIndex,
              onSelected: (index) {
                setState(() => _selectedCategoryIndex = index);
              },
            ),
          ),
          Expanded(child: _buildPlacesList()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RegionCode.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.xs),
        itemBuilder: (context, index) {
          final region = RegionCode.values[index];
          final isSelected = region == _selectedRegion;
          return ChoiceChip(
            label: Text(region.displayName),
            selected: isSelected,
            onSelected: (_) => _onRegionSelected(region),
            selectedColor: ChaerokColors.primary,
            backgroundColor: ChaerokColors.sageLight,
            labelStyle: ChaerokTypography.bodyMedium.copyWith(
              color: isSelected
                  ? ChaerokColors.surface
                  : ChaerokColors.primaryDark,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildPlacesList() {
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
            TextButton(onPressed: _fetchPlaces, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_places.isEmpty) {
      return const Center(
        child: Text('이 지역의 관광지 정보가 없어요', style: ChaerokTypography.bodyMedium),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      itemCount: _places.length,
      separatorBuilder: (_, _) => const SizedBox(height: ChaerokSpacing.sm),
      itemBuilder: (context, index) {
        final place = _places[index];
        return RecommendedPlaceCard(
          data: _toSummaryData(place, index),
          isFeatured: index == 0,
          onTap: () {},
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: const BoxDecoration(
        color: ChaerokColors.surface,
        border: Border(top: BorderSide(color: ChaerokColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ChaerokButton(
          text: '${_selectedRegion.displayName}에서 필름롤 시작하기',
          isEnabled: _regionId != null && !_isLoading,
          isLoading: _isEnteringFilmRoll,
          onPressed: _onEnterRegionTap,
        ),
      ),
    );
  }
}
