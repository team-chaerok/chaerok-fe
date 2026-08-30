import 'package:chaerok/core/config/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaultFilterId 저장/조회/삭제', () async {
    final prefs = AppPreferences.instance;
    expect(await prefs.getDefaultFilterId(), isNull);

    await prefs.setDefaultFilterId('vintage-01');
    expect(await prefs.getDefaultFilterId(), 'vintage-01');

    await prefs.setDefaultFilterId(null);
    expect(await prefs.getDefaultFilterId(), isNull);
  });
}
