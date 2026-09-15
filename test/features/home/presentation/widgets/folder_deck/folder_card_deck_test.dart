import 'package:chaerok/features/home/presentation/widgets/folder_deck/folder_card_deck.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 제네릭 동작 검증에는 지역/충남 홈 어느 쪽에도 묶이지 않는 String 탭을 쓴다.
  Widget host({required List<String> deckOrder, ValueChanged<String>? onOpen}) {
    return MaterialApp(
      home: Scaffold(
        body: FolderCardDeck<String>(
          deckOrder: deckOrder,
          onOpen: onOpen ?? (_) {},
          cardBuilder: (context, tab, opened) =>
              Center(child: Text(opened ? '$tab-열림' : '$tab-닫힘')),
        ),
      ),
    );
  }

  testWidgets('맨 뒤가 열린 카드, 나머지는 닫힌 카드로 렌더된다', (tester) async {
    await tester.pumpWidget(host(deckOrder: const ['a', 'b', 'c']));
    await tester.pumpAndSettle();

    expect(find.text('a-닫힘'), findsOneWidget);
    expect(find.text('b-닫힘'), findsOneWidget);
    expect(find.text('c-열림'), findsOneWidget);
  });

  testWidgets('닫힌 카드를 누르면 onOpen(해당 탭)을 호출한다', (tester) async {
    String? opened;
    await tester.pumpWidget(
      host(deckOrder: const ['a', 'b', 'c'], onOpen: (t) => opened = t),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('b-닫힘'));
    expect(opened, 'b');
  });

  testWidgets('열린 카드는 onOpen을 호출하지 않는다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(deckOrder: const ['a', 'b', 'c'], onOpen: (_) => calls++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('c-열림'), warnIfMissed: false);
    expect(calls, 0);
  });

  testWidgets('deckOrder가 바뀌면 새 탭이 열리고 이전 탭은 닫힌다', (tester) async {
    var order = const ['a', 'b', 'c'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FolderCardDeck<String>(
              deckOrder: order,
              onOpen: (t) =>
                  setState(() => order = FolderCardDeck.swapToFront(order, t)),
              cardBuilder: (context, tab, opened) =>
                  Center(child: Text(opened ? '$tab-열림' : '$tab-닫힘')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('c-열림'), findsOneWidget);

    await tester.tap(find.text('b-닫힘'));
    await tester.pumpAndSettle();

    expect(find.text('b-열림'), findsOneWidget);
    expect(find.text('c-닫힘'), findsOneWidget); // 직전 열린 카드는 닫힌 탭으로
    expect(find.text('a-닫힘'), findsOneWidget); // 나머지 위치는 유지
  });

  group('FolderCardDeck.swapToFront', () {
    test('탭 대상과 마지막 원소가 서로 자리를 맞바꾼다', () {
      final result = FolderCardDeck.swapToFront(['a', 'b', 'c', 'd'], 'b');
      expect(result, ['a', 'd', 'c', 'b']);
    });

    test('이미 마지막(열림)인 탭이면 그대로 반환한다', () {
      final order = ['a', 'b', 'c'];
      final result = FolderCardDeck.swapToFront(order, 'c');
      expect(result, order);
    });
  });
}
