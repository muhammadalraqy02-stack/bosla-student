import 'package:bosla_student/admin/admin_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('دور الحساب التجريبي يُكتشف من حقل role', () {
    expect(isDemoRole('تجريبي'), isTrue);
    expect(isDemoRole('تجريبي (عرض فقط)'), isTrue);
    expect(isDemoRole('حساب تجريبي لأبل'), isTrue);
    expect(isDemoRole('مشرف'), isFalse);
    expect(isDemoRole('مدير عام'), isFalse);
    expect(isDemoRole(''), isFalse);
  });

}
