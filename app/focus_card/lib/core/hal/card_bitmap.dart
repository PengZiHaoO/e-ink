/// H2 产物 · CardBitmap —— 1-bit 画布位图。
///
/// 字节布局（与固件的合同，配合 protocol.dart 阅读）：
/// - 行优先；每字节存 8 个水平像素；**MSB = 最左像素**
/// - 1 = 黑（ink），0 = 白（paper）
/// - 行宽非 8 倍数时末尾补位恒为 0（白）；Gen1 占位画布 296÷8=37 整除，无填充
library;

import 'dart:typed_data';

class CardBitmap {
  final int width;
  final int height;
  final Uint8List bytes;

  CardBitmap._(this.width, this.height, this.bytes);

  /// 每行字节数（stride）
  int get stride => (width + 7) ~/ 8;

  int get byteLength => stride * height;

  /// 从 RGBA 栅格阈值化：亮度 < threshold → 黑
  factory CardBitmap.fromRgba({
    required int width,
    required int height,
    required Uint8List rgba,
    int threshold = 128,
  }) {
    final stride = (width + 7) ~/ 8;
    final bytes = Uint8List(stride * height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        final lum =
            (rgba[i] * 299 + rgba[i + 1] * 587 + rgba[i + 2] * 114) ~/ 1000;
        if (lum < threshold) {
          bytes[y * stride + (x >> 3)] |= 0x80 >> (x & 7);
        }
      }
    }
    return CardBitmap._(width, height, bytes);
  }

  /// 全白位图
  factory CardBitmap.blank(int width, int height) =>
      CardBitmap._(width, height, Uint8List(((width + 7) ~/ 8) * height));

  /// 某像素是否为黑（越界恒为 false）
  bool pixelAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return false;
    return (bytes[y * stride + (x >> 3)] >> (7 - (x & 7))) & 1 == 1;
  }

  /// 全图黑像素占比（测试断言用）
  double blackRatio() => blackRatioIn(0, 0, width, height);

  /// 指定区域内黑像素占比（测试断言用）
  double blackRatioIn(int rx, int ry, int rw, int rh) {
    var black = 0, total = 0;
    for (var y = ry; y < ry + rh && y < height; y++) {
      for (var x = rx; x < rx + rw && x < width; x++) {
        total++;
        if (pixelAt(x, y)) black++;
      }
    }
    return total == 0 ? 0 : black / total;
  }
}
