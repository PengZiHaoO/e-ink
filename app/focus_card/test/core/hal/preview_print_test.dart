/// 渲染 ASCII 预览（评审用）：4× 降采样输出到测试日志。
/// 运行：flutter test test/core/hal/preview_print_test.dart --reporter expanded
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/card_renderer.dart';
import 'package:focus_card/core/hal/device_profile.dart';

import '../../helpers/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadCardFonts();
  });

  test('ASCII 预览：focusing 模板（4× 降采样）', () async {
    final renderer = CardRenderer(DeviceProfile.gen1Placeholder);
    final bmp = await renderer.render(const CardRenderInput(
      templateId: 'focusing',
      stateWord: 'FOCUSING',
      timeText: '14:32',
      customText: '15:30 后可打扰',
    ));
    debugPrint('--- CARD PREVIEW ${bmp.width}x${bmp.height} ---');
    for (var y = 0; y < bmp.height; y += 4) {
      final line = StringBuffer();
      for (var x = 0; x < bmp.width; x += 4) {
        var ink = false;
        for (var dy = 0; dy < 4 && !ink; dy++) {
          for (var dx = 0; dx < 4 && !ink; dx++) {
            if (bmp.pixelAt(x + dx, y + dy)) ink = true;
          }
        }
        line.write(ink ? '#' : '.');
      }
      debugPrint(line.toString());
    }
    debugPrint('--- END (black ratio: ${bmp.blackRatio().toStringAsFixed(3)}) ---');
  });
}
