import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_card.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 폴더 카드 스택 + 앞↔뒤 스와프 전환 실험 화면.
/// 값이 괜찮으면 이 레이아웃/애니메이션을 홈([RegionFilmDeck])으로 옮긴다.
class TestCardScreen extends StatefulWidget {
  const TestCardScreen({super.key});

  @override
  State<TestCardScreen> createState() => _TestCardScreenState();
}

class _TestCardScreenState extends State<TestCardScreen>
    with SingleTickerProviderStateMixin {
  // RegionFilmDeck에서 확정한 전환 값.
  static const Duration _duration = Duration(milliseconds: 320);
  static const double _recedeScaleMin = 0.98;
  static const double _recedePeak = 0.46;
  static const double _tiltRadians = 15 * math.pi / 180;
  static const double _staggerFraction = 170 / 320;
  static const double _advancePop = (1 - _recedeScaleMin) * 0.45;

  /// 겹친 카드가 아래로 밀리는 y 간격.
  static const double _peek = 32;

  /// 뒤로 갈수록 좌우로 더 좁아지는 폭(슬롯당).
  static const double _hInsetStep = 4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  static const _tag = 'TestCardScreen';
  static const _serviceProvinceName = '충청남도';

  /// 지역 스택 순서. 맨 뒤(0번 슬롯)가 제일 위, 맨 앞(마지막)이 열린 카드.
  final List<RegionCode> _order = RegionCode.values.toList();
  List<RegionCode> _fromOrder = const [];
  RegionCode? _incoming;
  RegionCode? _outgoing;

  // OutOfServiceHomeView와 동일한 지역 데이터 로더.
  final Map<RegionCode, _RegionData> _cache = {};
  final Map<RegionCode, int> _tokens = {};

  @override
  void initState() {
    super.initState();
    unawaited(_ensureLoaded(_order.last));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<int> _resolveRegionId(RegionCode region) async {
    final resolved = await RegionsApi.resolveRegion(
      ResolveRegionRequest(
        provinceName: _serviceProvinceName,
        cityCountyName: region.cityCountyName,
      ),
    );
    return resolved.regionId;
  }

  Future<void> _ensureLoaded(RegionCode region, {bool force = false}) async {
    final existing = _cache[region];
    if (!force &&
        existing != null &&
        existing.status == RegionLoadStatus.ready) {
      return;
    }
    final token = (_tokens[region] ?? 0) + 1;
    _tokens[region] = token;
    setState(() {
      _cache[region] = const _RegionData(status: RegionLoadStatus.loading);
    });
    try {
      final regionId = existing?.regionId ?? await _resolveRegionId(region);
      final places = await PlacesApi.getExternalPlaces(regionId);
      if (!mounted || _tokens[region] != token) return;
      setState(() {
        _cache[region] = _RegionData(
          status: RegionLoadStatus.ready,
          regionId: regionId,
          places: places,
        );
      });
    } catch (e, st) {
      log('지역 장소 로드 실패 ($region)', name: _tag, error: e, stackTrace: st);
      if (!mounted || _tokens[region] != token) return;
      setState(() {
        _cache[region] = _RegionData(
          status: RegionLoadStatus.error,
          regionId: existing?.regionId,
        );
      });
    }
  }

  void _onTap(RegionCode region) {
    if (_order.last == region || _controller.isAnimating) return;
    _fromOrder = List.of(_order);
    final k = _order.indexOf(region);
    final openIndex = _order.length - 1;
    _incoming = region;
    _outgoing = _order[openIndex];
    setState(() {
      _order[k] = _order[openIndex];
      _order[openIndex] = region;
    });
    unawaited(_controller.forward(from: 0));
    unawaited(_ensureLoaded(region));
  }

  double _lerp(num a, num b, double t) => a + (b - a) * t;

  double _recedeScale(double t) => t <= _recedePeak
      ? _lerp(1, _recedeScaleMin, t / _recedePeak)
      : _lerp(_recedeScaleMin, 1, (t - _recedePeak) / (1 - _recedePeak));

  double _recedeTilt(double t) => t <= _recedePeak
      ? _lerp(0, _tiltRadians, t / _recedePeak)
      : _lerp(_tiltRadians, 0, (t - _recedePeak) / (1 - _recedePeak));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('폴더 카드 전환 테스트')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : 600.0;
            final cardHeight = maxHeight - _peek * (_order.length - 1);
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final swapping = _incoming != null && _controller.value < 1;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final region in _order)
                      _card(
                        region: region,
                        cardHeight: cardHeight,
                        t: _controller.value,
                        swapping: swapping,
                        locked: _controller.isAnimating,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _card({
    required RegionCode region,
    required double cardHeight,
    required double t,
    required bool swapping,
    required bool locked,
  }) {
    final open = _order.last == region;
    final targetSlot = _order.indexOf(region);

    var slot = targetSlot.toDouble();
    var scale = 1.0;
    var tilt = 0.0;

    if (swapping) {
      final fromSlot = _fromOrder.indexOf(region);
      if (region == _incoming) {
        slot = _lerp(fromSlot, targetSlot, t);
        final u = ((t - _staggerFraction) / (1 - _staggerFraction)).clamp(
          0.0,
          1.0,
        );
        scale = 1 + _advancePop * (1 - u);
      } else if (region == _outgoing) {
        slot = _lerp(fromSlot, targetSlot, t);
        scale = _recedeScale(t);
        tilt = _recedeTilt(t);
      } else {
        slot = fromSlot.toDouble();
      }
    }

    final hInset = (_order.length - 1 - slot) * _hInsetStep;

    return Positioned(
      key: ValueKey<RegionCode>(region),
      left: hInset,
      right: hInset,
      top: slot * _peek,
      height: cardHeight,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..rotateX(tilt)
          ..scaleByDouble(scale, scale, 1, 1),
        child: GestureDetector(
          onTap: open || locked ? null : () => _onTap(region),
          child: _FolderCard(
            folderColor: region.filmTabColor,
            label: region.filmStripLabel,
            isFirst: open,
            body: open
                ? RegionDetailBody(
                    region: region,
                    status: _cache[region]?.status ?? RegionLoadStatus.loading,
                    places: _cache[region]?.places ?? const [],
                    onRetry: () =>
                        unawaited(_ensureLoaded(region, force: true)),
                    onExploreRegionRequested: (_) {},
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _RegionData {
  const _RegionData({
    required this.status,
    this.regionId,
    this.places = const [],
  });

  final RegionLoadStatus status;
  final int? regionId;
  final List<PlaceListResponse> places;
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folderColor,
    this.label,
    this.body,
    this.isFirst = false,
  });

  final Color folderColor;
  final String? label;

  /// 맨 앞(열린) 카드면 탭 아래 본문 영역에 채울 내용(RegionDetailBody).
  final Widget? body;

  /// 맨 앞(열린) 카드면 탭 아래 본문 영역을 채운다.
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _FolderCardShadowPainter(),
      child: ClipPath(
        clipper: const _FolderCardClipper(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: folderColor),
            if (isFirst)
              // 열린 카드: 탭 아래 본문 영역(크림 바탕 + 홈 RegionFilmCard 내용).
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                bottom: 0,
                child: ColoredBox(
                  color: ChaerokColors.primaryLight,
                  child: body ?? const SizedBox.shrink(),
                ),
              )
            else
              // 겹친 카드: 오른쪽 위에 지역 사진(현재는 자리만).
              const Positioned(
                top: 32,
                right: 0,
                width: 150,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(ChaerokRadius.lg),
                    ),
                  ),
                ),
              ),
            if (label != null)
              Positioned(
                left: 16,
                top: 6,
                child: Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `Rectangle 34626670.svg`의 폴더 탭 카드 실루엣.
/// 왼쪽 탭이 [_cardTop]만큼 위로 튀어나오고, 탭 오른쪽은 경사(대각선) →
/// 오목 이음으로 본문 상단에 붙는다. 모서리는 모두 [_r]. 탭 형상은 절대
/// 픽셀 값이라 카드 폭이 커져도 그대로다.
class _FolderCardClipper extends CustomClipper<Path> {
  const _FolderCardClipper();

  static const double _r = 16; // 모든 모서리 반경
  static const double _cardTop = 32; // 탭이 본문 위로 튀어나온 높이

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(0, _r)
      ..arcToPoint(const Offset(_r, 0), radius: const Radius.circular(_r))
      // 탭 상단 직선
      ..lineTo(147, 0)
      // 탭 오른쪽 위 라운딩
      ..cubicTo(152.36, 0, 157.37, 2.69, 160.33, 7.16)
      // 탭 오른쪽 경사
      ..lineTo(172.01, 24.8)
      // 탭 → 본문 상단 오목 이음
      ..cubicTo(174.98, 29.27, 179.99, _cardTop, 185.35, _cardTop)
      // 본문 상단
      ..lineTo(w - _r, _cardTop)
      ..arcToPoint(Offset(w, _cardTop + _r), radius: const Radius.circular(_r))
      // 오른쪽 변
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
      // 아래 변
      ..lineTo(_r, h)
      ..arcToPoint(Offset(0, h - _r), radius: const Radius.circular(_r))
      ..close();
  }

  @override
  bool shouldReclip(_FolderCardClipper oldClipper) => false;
}

/// 폴더 카드 외곽선을 따라 드롭 섀도우를 그린다([ClipPath]는 그림자를
/// 만들지 않으므로 별도로 얹는다).
class _FolderCardShadowPainter extends CustomPainter {
  const _FolderCardShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      const _FolderCardClipper().getClip(size),
      Colors.black,
      3,
      false,
    );
  }

  @override
  bool shouldRepaint(_FolderCardShadowPainter oldDelegate) => false;
}
