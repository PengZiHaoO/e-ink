import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/card_writer.dart';

void main() {
  group('H6/W2 · MockCardWriter', () {
    test('成功路径：返回 WriteSuccess(bytesWritten)', () async {
      final w = MockCardWriter(delay: Duration.zero);
      expect(await w.isAvailable(), isTrue);
      final r = await w.write(Uint8List.fromList([1, 2, 3]));
      expect(r, isA<WriteSuccess>());
      expect((r as WriteSuccess).bytesWritten, 3);
    });

    test('失败注入 failureRate=1：返回 WriteFailure(timeout)', () async {
      final w = MockCardWriter(
        delay: Duration.zero,
        failureRate: 1.0,
        random: Random(1),
      );
      final r = await w.write(Uint8List(4));
      expect(r, isA<WriteFailure>());
      expect((r as WriteFailure).kind, WriteErrorKind.timeout);
    });

    test('failureRate=0 永不失败（确定性）', () async {
      final w = MockCardWriter(
        delay: Duration.zero,
        failureRate: 0.0,
        random: Random(42),
      );
      for (var i = 0; i < 20; i++) {
        expect(await w.write(Uint8List(1)), isA<WriteSuccess>());
      }
    });
  });

  group('H6 · 平台工厂', () {
    test('返回可用 writer（M1 阶段全平台 Mock）', () {
      expect(createPlatformCardWriter(), isA<CardWriter>());
    });
  });

  group('H6 · WriteResult sealed 穷尽性', () {
    test('switch 覆盖成功/失败两分支', () {
      String describe(WriteResult r) => switch (r) {
            WriteSuccess(:final bytesWritten) => 'ok:$bytesWritten',
            WriteFailure(:final kind) => 'fail:${kind.name}',
          };
      expect(describe(const WriteSuccess(9)), 'ok:9');
      expect(describe(const WriteFailure(WriteErrorKind.tagLost)),
          'fail:tagLost');
    });
  });
}
