import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'outOfServiceArea 상태에서 "지역별로 둘러보기" 탭 시 LocationOutOfService를 pop 한다',
    (tester) async {
      LocationVerificationResult.outOfServiceSessionCache = false;
      LocationVerificationOutcome? popped;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    popped = await Navigator.of(context)
                        .push<LocationVerificationOutcome>(
                          MaterialPageRoute(
                            builder: (_) => const LocationVerificationScreen(
                              debugInitialOutOfServiceArea: true,
                            ),
                          ),
                        );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('지역별로 둘러보기'), findsOneWidget);
      await tester.tap(find.text('지역별로 둘러보기'));
      await tester.pumpAndSettle();

      expect(popped, isA<LocationOutOfService>());
      expect(LocationVerificationResult.outOfServiceSessionCache, isTrue);
    },
  );
}
