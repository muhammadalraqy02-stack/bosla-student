import 'package:flutter_test/flutter_test.dart';
import 'package:bosla_student/utils.dart';

void main() {
  test('توحيد رقم الواتساب العراقي', () {
    expect(normWa('07801234567'), '9647801234567');
    expect(normWa('009647801234567'), '9647801234567');
    expect(normWa('7801234567'), '9647801234567');
  });
  test('قراءة الإحداثيات من رابط أو نص', () {
    final g = parseGeo('31.8356,47.1440');
    expect(g != null, true);
    expect(g!.lat, closeTo(31.8356, 0.0001));
  });
}
