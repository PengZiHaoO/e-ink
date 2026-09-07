import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/protocol.dart';

void main() {
  group('H3 · CRC16-CCITT-FALSE', () {
    test('标准校验值 "123456789" == 0x29B1', () {
      expect(crc16Ccitt('123456789'.codeUnits), 0x29B1);
    });

    test('空输入 == init 值 0xFFFF', () {
      expect(crc16Ccitt(const []), 0xFFFF);
    });
  });

  group('H3 · CardFrame v0', () {
    test('round-trip：空图像', () {
      final f = CardFrame(deviceId: 1, imageData: Uint8List(0));
      final d = CardFrame.decode(f.encode());
      expect(d.version, 0);
      expect(d.flags, 0);
      expect(d.deviceId, 1);
      expect(d.compression, CardFrame.compressionNone);
      expect(d.imageData.length, 0);
    });

    test('round-trip：4736B 满画布（Gen1 占位原始位图）', () {
      final data =
          Uint8List.fromList(List.generate(296 * 128 ~/ 8, (i) => i % 251));
      final f = CardFrame(
        deviceId: 0xDEADBEEF,
        compression: CardFrame.compressionRle,
        imageData: data,
      );
      final d = CardFrame.decode(f.encode());
      expect(d.deviceId, 0xDEADBEEF);
      expect(d.compression, CardFrame.compressionRle);
      expect(d.imageData, data);
    });

    test('deviceId u32 上界不失真', () {
      final f = CardFrame(deviceId: 0xFFFFFFFF, imageData: Uint8List(0));
      expect(CardFrame.decode(f.encode()).deviceId, 0xFFFFFFFF);
    });

    test('encodedSize == encode().length == 13 + imageData', () {
      final f = CardFrame(deviceId: 7, imageData: Uint8List(100));
      expect(f.encodedSize, f.encode().length);
      expect(f.encodedSize, CardFrame.frameOverheadBytes + 100);
    });

    test('CRC 损坏被拒绝', () {
      final bytes =
          CardFrame(deviceId: 1, imageData: Uint8List.fromList([1, 2, 3])).encode();
      bytes[bytes.length - 1] ^= 0xFF;
      expect(() => CardFrame.decode(bytes), throwsA(isA<ProtocolException>()));
    });

    test('Magic 损坏被拒绝', () {
      final bytes = CardFrame(deviceId: 1, imageData: Uint8List(0)).encode();
      bytes[0] = 0x00;
      expect(() => CardFrame.decode(bytes), throwsA(isA<ProtocolException>()));
    });

    test('帧过短被拒绝', () {
      expect(() => CardFrame.decode(const [1, 2, 3]),
          throwsA(isA<ProtocolException>()));
    });

    test('ImageData 长度不符（CRC 正确）被拒绝', () {
      // 手工构帧：声明 imageSize=5，实际数据 2 字节，再算正确 CRC
      final body = <int>[
        0x46, 0x43, // Magic "FC"
        0x00, // Version
        0x00, // Flags
        0x00, 0x00, 0x00, 0x01, // DeviceID = 1
        0x00, 0x05, // ImageSize = 5（撒谎）
        0x00, // Compression
        0x01, 0x02, // 实际 2 字节
      ];
      final crc = crc16Ccitt(body);
      final bytes =
          Uint8List.fromList([...body, (crc >> 8) & 0xFF, crc & 0xFF]);
      expect(() => CardFrame.decode(bytes), throwsA(isA<ProtocolException>()));
    });
  });
}
