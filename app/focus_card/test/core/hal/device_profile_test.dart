import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/device_profile.dart';
import 'package:focus_card/core/hal/protocol.dart';

void main() {
  final p = DeviceProfile.gen1Placeholder;

  group('H1 · Gen1 占位 profile', () {
    test('基础参数', () {
      expect(p.canvasW, 296);
      expect(p.canvasH, 128);
      expect(p.colorDepth, 1);
      expect(p.generation, 1);
      expect(p.protocolVersion, 0);
      expect(p.compressions, containsAll([0, 1]));
    });

    test('画布字节 = 4736（296×128 1-bit）', () {
      expect(p.canvasBytes, 296 * 128 ~/ 8);
      expect(p.canvasBytes, 4736);
    });

    test('满画布未压缩帧装得进 payload 预算', () {
      final frame = CardFrame(deviceId: 1, imageData: Uint8List(p.canvasBytes));
      expect(frame.encodedSize, p.canvasBytes + CardFrame.frameOverheadBytes);
      expect(p.fitsPayload(frame.encodedSize), isTrue);
      expect(p.payloadBudget, p.memoryLimitBytes - p.ndefOverheadBytes);
    });

    test('超预算 payload 被拒（W5 预检判定依据）', () {
      expect(p.fitsPayload(p.payloadBudget + 1), isFalse);
    });
  });

  group('H1 · 布局规则', () {
    test('五模板齐全且全部区域在画布内', () {
      final canvas = Region(0, 0, p.canvasW, p.canvasH);
      for (final id in ['focusing', 'break', 'available', 'away', 'card']) {
        final rule = p.layoutFor(id);
        expect(rule, isNotNull, reason: '缺模板: $id');
        expect(rule!.templateId, id);
        for (final r in rule.regions.values) {
          expect(canvas.contains(r), isTrue, reason: '$id 区域越界: $r');
        }
      }
    });

    test('文字模板含 stateWord/time/customText；名片含 name/title/qr', () {
      for (final id in ['focusing', 'break', 'available', 'away']) {
        expect(p.layoutFor(id)!.regions.keys,
            containsAll(['stateWord', 'time', 'customText']),
            reason: id);
      }
      expect(p.layoutFor('card')!.regions.keys,
          containsAll(['name', 'title', 'qr']));
    });

    test('字体规则下限：状态词≥40 / 时间≥28 / CJK≥24', () {
      expect(p.fontRules.stateWordMinPx, greaterThanOrEqualTo(40));
      expect(p.fontRules.timeMinPx, greaterThanOrEqualTo(28));
      expect(p.fontRules.cjkMinPx, greaterThanOrEqualTo(24));
    });
  });
}
