import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/qr_bitmap.dart';

void main() {
  test('空内容 → null', () {
    expect(renderQrBitmap(''), isNull);
    expect(renderQrBitmap('   '), isNull);
  });

  test('确定性：同内容同位图', () {
    final a = renderQrBitmap('https://focus.card/zihao');
    final b = renderQrBitmap('https://focus.card/zihao');
    expect(a, isNotNull);
    expect(a!.bytes, b!.bytes);
  });

  test('正方形 + 尺寸 = (modules + quiet*2) * scale', () {
    final bmp = renderQrBitmap('HELLO', scale: 3, quietZone: 2)!;
    expect(bmp.width, bmp.height);
    // 宽度必为 scale 的整数倍且含 quiet zone 边
    expect(bmp.width % 3, 0);
    expect(bmp.width, greaterThan(21 * 3));
  });

  test('quiet zone 全白（扫码器需要静区）', () {
    final bmp = renderQrBitmap('HELLO', scale: 3, quietZone: 2)!;
    for (var i = 0; i < 6; i++) {
      expect(bmp.pixelAt(i, i), isFalse);
      expect(bmp.pixelAt(bmp.width - 1 - i, i), isFalse);
    }
  });

  test('黑占比在合理区间（有 finder 图案但非全黑）', () {
    final r = renderQrBitmap('HELLO WORLD')!.blackRatio();
    expect(r, greaterThan(0.1));
    expect(r, lessThan(0.6));
  });
}
