/// P3 · QR 内容 → 1-bit CardBitmap（纯计算，可单测）。
/// 黑模块 = ink(1)，含 quiet zone；失败（内容过长等）返回 null。
library;

import 'package:qr/qr.dart';

import 'card_bitmap.dart';

CardBitmap? renderQrBitmap(
  String content, {
  int scale = 3,
  int quietZone = 2,
}) {
  if (content.trim().isEmpty) return null;
  try {
    final code = QrCode(payload: QrPayload.fromString(content));
    final img = QrImage(code);
    final n = code.moduleCount;
    final size = (n + quietZone * 2) * scale;
    final bmp = CardBitmap.blank(size, size);
    final bytes = bmp.bytes;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!img.isDark(r, c)) continue;
        final y0 = (r + quietZone) * scale;
        final x0 = (c + quietZone) * scale;
        for (var dy = 0; dy < scale; dy++) {
          for (var dx = 0; dx < scale; dx++) {
            final px = x0 + dx;
            final py = y0 + dy;
            bytes[py * bmp.stride + (px >> 3)] |= 0x80 >> (px & 7);
          }
        }
      }
    }
    return bmp;
  } on InputTooLongException {
    return null;
  }
}
