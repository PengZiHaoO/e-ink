/// 屏3「记录」—— M1 过渡版：静默落库已在跑（S3→SessionLog），
/// 正式统计/streak/补记在 T5（M2）建成。当前显示会话流水证明管线通。
library;

import 'package:flutter/material.dart';

import '../app/deps.dart';
import '../app/theme.dart';

class RecordsScreen extends StatelessWidget {
  final AppDeps deps;
  const RecordsScreen({super.key, required this.deps});

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: deps.sessionLog,
      builder: (context, _) {
        final log = deps.sessionLog;
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(T.s2, T.s2, T.s2, T.s3),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('记录', style: T.title),
                    const SizedBox(height: T.s1),
                    Text('统计页建设中（M2）—— 会话已在静默记录',
                        style: T.caption),
                    const SizedBox(height: T.s3),
                    Text('${log.count}', style: T.display),
                    Text('已记录会话', style: T.body.copyWith(color: T.inkSub)),
                    const SizedBox(height: T.s3),
                    if (log.records.isEmpty)
                      Text('切换一次状态，这里就会出现第一条会话',
                          style: T.body.copyWith(color: T.inkSub))
                    else
                      for (final r in log.records.reversed)
                        Container(
                          margin: const EdgeInsets.only(bottom: T.s1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: T.s2, vertical: T.s1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(T.rButton),
                            border: Border.all(color: T.line),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: r.state.isFocus ? T.accent : T.inkSub,
                                ),
                              ),
                              const SizedBox(width: T.s1),
                              Text(r.state.buttonLabelZh, style: T.body),
                              const Spacer(),
                              Text(
                                '${_hhmm(r.start)}–${_hhmm(r.end)} · ${r.duration.inMinutes}m',
                                style: T.caption,
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
