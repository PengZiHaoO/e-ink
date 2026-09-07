/// H3 · 协议 v0 编解码 + CRC16 校验。
///
/// 帧结构（App ↔ 卡片固件的合同；活文档——两端同队开发，过程中对齐更新，
/// 见《App功能全景_V1.md》§4.2 评审结论）：
///
/// | 偏移 | 字段        | 类型   | 字节 | 说明                     |
/// |-----:|-------------|--------|-----:|--------------------------|
/// |    0 | Magic       | char[2]|   2  | "FC"                     |
/// |    2 | Version     | u8     |   1  | 协议版本 = 0              |
/// |    3 | Flags       | u8     |   1  | 保留 = 0                  |
/// |    4 | DeviceID    | u32    |   4  | 绑定 UID 哈希，防错写到别的卡 |
/// |    8 | ImageSize   | u16    |   2  | ImageData 字节数          |
/// |   10 | Compression | u8     |   1  | 0=none，1=RLE             |
/// |   11 | ImageData   | var    |  ≤7.9K| 位图数据                  |
/// |  尾  | CRC16       | u16    |   2  | CCITT-FALSE，覆盖 Magic~ImageData |
///
/// 设计原则：bitmap-centric——卡片固件是哑终端（收位图→刷屏），智能全在 App。
library;

import 'dart:typed_data';

class ProtocolException implements Exception {
  final String message;
  ProtocolException(this.message);

  @override
  String toString() => 'ProtocolException: $message';
}

/// CRC16-CCITT-FALSE：poly 0x1021，init 0xFFFF，无反射，无最终异或。
/// 标准校验值：crc16Ccitt("123456789".codeUnits) == 0x29B1
int crc16Ccitt(List<int> data) {
  var crc = 0xFFFF;
  for (final byte in data) {
    crc ^= (byte & 0xFF) << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
    }
  }
  return crc;
}

class CardFrame {
  static const int magicF = 0x46; // 'F'
  static const int magicC = 0x43; // 'C'
  static const int headerBytes = 11;
  static const int crcBytes = 2;
  static const int frameOverheadBytes = headerBytes + crcBytes; // 13

  static const int compressionNone = 0;
  static const int compressionRle = 1;

  final int version;
  final int flags;

  /// u32：绑定 UID 哈希低 4 字节（D1/D2）
  final int deviceId;
  final int compression;
  final Uint8List imageData;

  CardFrame({
    this.version = 0,
    this.flags = 0,
    required this.deviceId,
    this.compression = compressionNone,
    required this.imageData,
  });

  int get encodedSize => frameOverheadBytes + imageData.length;

  /// 编码为大端字节帧（含尾部 CRC16）
  Uint8List encode() {
    final body = BytesBuilder(copy: false);
    body.addByte(magicF);
    body.addByte(magicC);
    body.addByte(version & 0xFF);
    body.addByte(flags & 0xFF);
    body.addByte((deviceId >> 24) & 0xFF);
    body.addByte((deviceId >> 16) & 0xFF);
    body.addByte((deviceId >> 8) & 0xFF);
    body.addByte(deviceId & 0xFF);
    body.addByte((imageData.length >> 8) & 0xFF);
    body.addByte(imageData.length & 0xFF);
    body.addByte(compression & 0xFF);
    body.add(imageData);

    final bodyBytes = body.toBytes();
    final crc = crc16Ccitt(bodyBytes);
    final frame = Uint8List(bodyBytes.length + crcBytes);
    frame.setRange(0, bodyBytes.length, bodyBytes);
    frame[bodyBytes.length] = (crc >> 8) & 0xFF;
    frame[bodyBytes.length + 1] = crc & 0xFF;
    return frame;
  }

  /// 解码并校验。任何结构性错误抛 [ProtocolException]。
  static CardFrame decode(List<int> bytes) {
    if (bytes.length < frameOverheadBytes) {
      throw ProtocolException('帧过短: ${bytes.length}B < ${frameOverheadBytes}B');
    }
    if (bytes[0] != magicF || bytes[1] != magicC) {
      throw ProtocolException('Magic 错误: 期望 "FC"');
    }
    final bodyLen = bytes.length - crcBytes;
    final crcInFrame = ((bytes[bodyLen] & 0xFF) << 8) | (bytes[bodyLen + 1] & 0xFF);
    if (crc16Ccitt(bytes.sublist(0, bodyLen)) != crcInFrame) {
      throw ProtocolException('CRC 校验失败');
    }
    final deviceId = (((bytes[4] & 0xFF) << 24) |
            ((bytes[5] & 0xFF) << 16) |
            ((bytes[6] & 0xFF) << 8) |
            (bytes[7] & 0xFF)) &
        0xFFFFFFFF;
    final imageSize = ((bytes[8] & 0xFF) << 8) | (bytes[9] & 0xFF);
    final actualSize = bodyLen - headerBytes;
    if (actualSize != imageSize) {
      throw ProtocolException('ImageData 长度不符: 声明 $imageSize, 实际 $actualSize');
    }
    return CardFrame(
      version: bytes[2] & 0xFF,
      flags: bytes[3] & 0xFF,
      deviceId: deviceId,
      compression: bytes[10] & 0xFF,
      imageData: Uint8List.fromList(bytes.sublist(headerBytes, bodyLen)),
    );
  }
}
