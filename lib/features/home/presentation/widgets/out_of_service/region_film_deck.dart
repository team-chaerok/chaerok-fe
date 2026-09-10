import 'dart:async';
import 'dart:math' as math;

import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/folder_card_shape.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_card.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 지역별 필름롤 카드 한 장의 데이터(로드 상태 + 장소 목록).
typedef RegionFilmData = ({
  RegionLoadStatus status,
  List<PlaceListResponse> places,
});

/// 충남 외 지역 홈 상단의 "필름롤" 스택. [deckOrder]의 맨 뒤 원소가 열린 카드이고,
/// 나머지는 위에 탭만 겹쳐 쌓인다. 겹친 탭을 누르면 [onOpen]으로 전환을 요청하며,
/// 부모가 그 지역과 직전에 열려 있던 지역의 덱 순서를 스위치하면 두 카드가
/// 앞뒤로 자리를 맞바꾸는 전환 애니메이션이 재생된다(값은 프로토타입 확정치).
class RegionFilmDeck extends StatefulWidget {
  const RegionFilmDeck({
    super.key,
    required this.deckOrder,
    required this.dataByRegion,
    required this.onOpen,
    required this.onRetry,
    required this.onExploreRegionRequested,
  });

  final List<RegionCode> deckOrder;
  final Map<RegionCode, RegionFilmData> dataByRegion;
  final ValueChanged<RegionCode> onOpen;
  final ValueChanged<RegionCode> onRetry;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  @override
  State<RegionFilmDeck> createState() => _RegionFilmDeckState();
}

class _RegionFilmDeckState extends State<RegionFilmDeck>
    with SingleTickerProviderStateMixin {
  // "필름롤 카드 전환" 프로토타입에서 확정한 값.
  static const Duration _duration = Duration(milliseconds: 320);
  static const double _recedeScaleMin = 0.98; // 물러나는 카드 최소 배율
  static const double _recedePeak = 0.46; // 배율·기울기 정점 시점
  static const double _tiltRadians = 15 * math.pi / 180; // 뒤로 눕는 각
  static const double _staggerFraction = 170 / 320; // 수신 카드 진입 지연 비율
  static const double _advancePop = (1 - _recedeScaleMin) * 0.45; // 수신 카드 미세 팝

  /// 겹친 카드가 아래로 밀리는 y 간격 = 폴더 탭 돌출 높이.
  static const double _peek = FolderCardClipper.cardTop;

  /// 뒤 카드일수록 좌우로 더 좁아지는 폭(슬롯당).
  static const double _hInsetStep = 4;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  List<RegionCode> _fromOrder = const [];
  RegionCode? _incoming;
  RegionCode? _outgoing;

  @override
  void initState() {
    super.initState();
    _fromOrder = widget.deckOrder;
  }

  @override
  void didUpdateWidget(RegionFilmDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deckOrder.last != widget.deckOrder.last) {
      _fromOrder = oldWidget.deckOrder;
      _incoming = widget.deckOrder.last;
      _outgoing = oldWidget.deckOrder.last;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _controller.value = 1;
      } else {
        unawaited(_controller.forward(from: 0));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _lerp(num a, num b, double t) => a + (b - a) * t;

  /// 1 → [_recedeScaleMin] → 1 (정점 [_recedePeak]).
  double _recedeScale(double t) => t <= _recedePeak
      ? _lerp(1, _recedeScaleMin, t / _recedePeak)
      : _lerp(_recedeScaleMin, 1, (t - _recedePeak) / (1 - _recedePeak));

  /// 0 → [_tiltRadians] → 0 (정점 [_recedePeak]).
  double _recedeTilt(double t) => t <= _recedePeak
      ? _lerp(0, _tiltRadians, t / _recedePeak)
      : _lerp(_tiltRadians, 0, (t - _recedePeak) / (1 - _recedePeak));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const peek = _peek;
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 600.0;
        final cardHeight = maxHeight - peek * (widget.deckOrder.length - 1);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final swapping = _incoming != null && _controller.value < 1;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final region in widget.deckOrder)
                  _card(
                    region: region,
                    peek: peek,
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
    );
  }

  Widget _card({
    required RegionCode region,
    required double peek,
    required double cardHeight,
    required double t,
    required bool swapping,
    required bool locked,
  }) {
    final open = region == widget.deckOrder.last;
    final targetSlot = widget.deckOrder.indexOf(region);

    var slot = targetSlot.toDouble();
    var scale = 1.0;
    var tilt = 0.0;

    if (swapping) {
      final fromSlot = _fromOrder.indexOf(region);
      if (region == _incoming) {
        // 위치는 물러나는 카드와 동시에 미끄러진다(프로토타입은 top 전환에
        // 지연이 없어 두 카드가 t=0부터 교차한다). 스태거는 미세 팝만 늦춘다.
        slot = _lerp(fromSlot, targetSlot, t);
        final u = ((t - _staggerFraction) / (1 - _staggerFraction)).clamp(
          0.0,
          1.0,
        );
        scale = 1 + _advancePop * (1 - u);
      } else if (region == _outgoing) {
        // 물러나는 카드는 탭이 뒤로 눌리며 스택으로 밀려 들어간다.
        slot = _lerp(fromSlot, targetSlot, t);
        scale = _recedeScale(t);
        tilt = _recedeTilt(t);
      } else {
        slot = fromSlot.toDouble(); // targetSlot과 동일 — 고정
      }
    }

    // 뒤 카드일수록 좌우로 좁아진다. slot이 소수여도 부드럽게 이어진다.
    final hInset = (widget.deckOrder.length - 1 - slot) * _hInsetStep;

    return Positioned(
      key: ValueKey<RegionCode>(region),
      left: hInset,
      right: hInset,
      top: slot * peek,
      height: cardHeight,
      child: Transform(
        // 프로토타입과 동일하게 원근 없는 정사영 — rotateX는 세로로 살짝
        // 눌리는 효과만 낸다(하단 기준).
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..rotateX(tilt)
          ..scaleByDouble(scale, scale, 1, 1),
        child: GestureDetector(
          onTap: open || locked ? null : () => widget.onOpen(region),
          child: RegionFilmCard(
            region: region,
            status:
                widget.dataByRegion[region]?.status ?? RegionLoadStatus.loading,
            places:
                widget.dataByRegion[region]?.places ??
                const <PlaceListResponse>[],
            onRetry: () => widget.onRetry(region),
            onExploreRegionRequested: widget.onExploreRegionRequested,
            opened: open,
          ),
        ),
      ),
    );
  }
}
