import 'package:flutter_test/flutter_test.dart';
import 'package:healthq/theme/app_colors.dart';

void main() {
  test('App color palette smoke test', () {
    expect(OpdColors.primary500, isNotNull);
    expect(OpdColors.primary400, isNotNull);
    expect(OpdColors.primary100, isNotNull);
    expect(OpdColors.statusWaitingBg, isNotNull);
  });
}
