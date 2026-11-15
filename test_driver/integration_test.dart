// مشغّل الفحص على المحاكي: يحفظ صور الشاشات وتقرير النتائج في ios_test_out/
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final f = await File('ios_test_out/screens/$name.png').create(recursive: true);
        await f.writeAsBytes(bytes);
        return true;
      },
    );
