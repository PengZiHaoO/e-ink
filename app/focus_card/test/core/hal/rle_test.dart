import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/rle.dart';

Uint8List _randomBytes(int n, int seed) {
  final r = Random(seed);
  return Uint8List.fromList(List.generate(n, (_) => r.nextInt(256)));
}

void main() {
  group('H4 · RLE round-trip', () {
    test('空数据', () {
      expect(rleEncode(const []).length, 0);
      expect(rleDecode(rleEncode(const [])).length, 0);
    });

    test('单字节', () {
      expect(rleDecode(rleEncode(const [42])), const [42]);
    });

    test('全零 4736B（空白卡位图）→ 高压缩', () {
      final data = List.filled(296 * 128 ~/ 8, 0);
      final enc = rleEncode(data);
      // 4736 = 37×128 → 37 个 repeat 块 × 2B = 74B
      expect(enc.length, lessThan(96));
      expect(rleDecode(enc), data);
    });

    test('重复段边界 127/128/129/255/256', () {
      for (final n in [1, 2, 3, 127, 128, 129, 255, 256]) {
        final data = List.filled(n, 0xAB);
        expect(rleDecode(rleEncode(data)), data, reason: 'n=$n');
      }
    });

    test('交替字面量 300B', () {
      final data = List.generate(300, (i) => i % 256);
      expect(rleDecode(rleEncode(data)), data);
    });

    test('伪随机（不可压）4736B：round-trip + 膨胀有界', () {
      final data = _randomBytes(296 * 128 ~/ 8, 7);
      final enc = rleEncode(data);
      expect(rleDecode(enc), data);
      // 随机数据几乎无 3 连重复 → 膨胀 ≤ ~1/128
      expect(enc.length, lessThanOrEqualTo(data.length + data.length ~/ 64 + 2));
    });

    test('文字位图模式（大段 0 + 稀疏 0xFF）→ 显著压缩', () {
      final data = <int>[];
      for (var row = 0; row < 128; row++) {
        for (var col = 0; col < 37; col++) {
          final ink = row > 40 && row < 90 && col > 2 && col < 30 &&
              (row * col) % 7 == 0;
          data.add(ink ? 0xFF : 0x00);
        }
      }
      final enc = rleEncode(data);
      expect(rleDecode(enc), data);
      expect(enc.length, lessThan(data.length ~/ 2));
    });
  });

  group('H4 · RLE 损坏数据', () {
    test('字面段越界抛 FormatException', () {
      // 控制字节 5 → 声称 6 个字面量，实际只有 2 个
      expect(() => rleDecode(const [5, 1, 2]), throwsFormatException);
    });

    test('重复段缺数据字节抛 FormatException', () {
      expect(() => rleDecode(const [200]), throwsFormatException);
    });

    test('保留控制字节 128 被跳过', () {
      expect(rleDecode(const [128, 0, 0x41]), const [0x41]);
    });
  });
}
