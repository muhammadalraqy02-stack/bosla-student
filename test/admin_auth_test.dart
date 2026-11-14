import 'package:flutter_test/flutter_test.dart';
import 'package:bosla_student/admin/admin_auth.dart';

// القيم المرجعية محسوبة بمكتبة قياسية (PBKDF2-HMAC-SHA256) وبنفس خوارزمية FNV في نسخة الويب،
// للتأكد أن كلمات مرور المدير المحفوظة من الويب تُقبل في التطبيق والعكس.
void main() {
  test('PBKDF2 مطابق لنسخة الويب', () async {
    final d = await strongPassword('كلمةSecret2026', '0123456789abcdef0123456789abcdef');
    expect(d, 'fceecedea5f1aa3259aa8f2b827b75777c847cc9fde3e38f30491fc8856a5b60');
    expect(
      await verifyPassword(
        'كلمةSecret2026',
        'pbkdf2\$0123456789abcdef0123456789abcdef\$fceecedea5f1aa3259aa8f2b827b75777c847cc9fde3e38f30491fc8856a5b60',
      ),
      true,
    );
    expect(await verifyPassword('wrong', 'pbkdf2\$0123456789abcdef0123456789abcdef\$$d'), false);
  });

  test('البصمة القديمة مطابقة لنسخة الويب', () async {
    expect(legacyHash('Admin@2026'), 'ffe34406');
    expect(legacyHash('مرحبا'), 'be020bf3');
    expect(await verifyPassword('Admin@2026', 'ffe34406'), true);
  });

  test('سجل كلمة مرور جديد قابل للتحقق', () async {
    final rec = await makePasswordRecord('NewPass2026x');
    expect(rec.startsWith('pbkdf2\$'), true);
    expect(await verifyPassword('NewPass2026x', rec), true);
  });

  test('شروط كلمة المرور', () {
    expect(validPassword('short1'), false);
    expect(validPassword('onlyletterspass'), false);
    expect(validPassword('Good2026pass'), true);
  });
}
