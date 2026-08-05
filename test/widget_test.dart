import 'package:chinese_tracker/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HSK levels and term sizes are configured', () {
    expect(AppConstants.hskLevels, hasLength(6));
    expect(AppConstants.hskLevels.first, 'HSK 1');
    expect(AppConstants.termSizes, [8, 16]);
  });
}
