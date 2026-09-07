/// H4 · RLE 压缩（PackBits 变体，字节导向）。
///
/// 控制字节 c：
/// - `0..127`   → 字面复制后续 c+1 字节
/// - `129..255` → 重复后续 1 字节 (257-c) 次
/// - `128`      → 保留（解码跳过）
///
/// 设计目标：1-bit 文字位图（大段 0x00/0xFF 行）→ 文字态典型 <1KB。
/// 最坏情况（3 字节周期性重复）膨胀 ≤ ~1.34x，但 1-bit 内容不会出现；
/// 随机数据膨胀 ≤ ~1.01x。容量兜底由 W5 预检负责（超限直接拒发）。
library;

import 'dart:typed_data';

Uint8List rleEncode(List<int> data) {
  final out = BytesBuilder(copy: false);
  var i = 0;
  while (i < data.length) {
    // 探测当前位置的重复段长度（上限 128）
    var run = 1;
    while (run < 128 && i + run < data.length && data[i + run] == data[i]) {
      run++;
    }
    if (run >= 3) {
      out.addByte(257 - run);
      out.addByte(data[i] & 0xFF);
      i += run;
    } else {
      // 字面段：前进直到遇见 ≥3 的重复段或满 128 字节
      final start = i;
      var lit = 0;
      while (i < data.length && lit < 128) {
        if (i + 2 < data.length &&
            data[i] == data[i + 1] &&
            data[i + 1] == data[i + 2]) {
          break;
        }
        i++;
        lit++;
      }
      if (lit == 0) {
        // 防御性前进（理论上不可达：run≥3 已被 repeat 分支处理）
        i++;
        lit = 1;
      }
      out.addByte(lit - 1);
      out.add(data.sublist(start, start + lit));
    }
  }
  return out.toBytes();
}

/// 解码。数据损坏（段越界）抛 [FormatException]。
Uint8List rleDecode(List<int> data) {
  final out = BytesBuilder(copy: false);
  var i = 0;
  while (i < data.length) {
    final c = data[i++] & 0xFF;
    if (c == 128) continue;
    if (c < 128) {
      final n = c + 1;
      if (i + n > data.length) {
        throw FormatException('RLE 字面段越界: 需 $n 字节, 剩 ${data.length - i}');
      }
      out.add(data.sublist(i, i + n));
      i += n;
    } else {
      final n = 257 - c;
      if (i >= data.length) {
        throw const FormatException('RLE 重复段缺少数据字节');
      }
      out.add(List<int>.filled(n, data[i++] & 0xFF));
    }
  }
  return out.toBytes();
}
