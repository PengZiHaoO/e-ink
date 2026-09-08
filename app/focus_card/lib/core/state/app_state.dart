/// S4 模型 · AppState —— 已提交的"当前状态快照"（重启恢复的单位）。
///
/// 字段语义（2026-09-08 细化）：
/// - currentState/since/customText：**只在写卡成功后变更**（S3 铁律）
/// - lastWriteTs/lastWriteStatus：最近一次写入**尝试**（成败都记）
/// - lastSuccessTs：最近一次**成功**写入——`isCardSynced` 的判定依据。
///   分开记的原因：失败尝试不能抹掉"卡上现在是什么"的事实，
///   否则失败后再次成功切换会丢失整段会话（J7→J3 组合场景）。
library;

import 'card_state.dart';

class AppState {
  final CardState currentState;
  final DateTime since;
  final String? customText;
  final DateTime? lastWriteTs;

  /// 'success' | WriteErrorKind.name（字符串存储，避免模型层耦合 W 域枚举）
  final String? lastWriteStatus;
  final DateTime? lastSuccessTs;

  const AppState({
    required this.currentState,
    required this.since,
    this.customText,
    this.lastWriteTs,
    this.lastWriteStatus,
    this.lastSuccessTs,
  });

  /// 卡上内容 = currentState（自 since 起）——即"当前状态曾成功上卡"
  bool get isCardSynced => lastSuccessTs != null;

  /// 首次安装默认：可打扰、未写卡
  factory AppState.initial({DateTime? now}) => AppState(
        currentState: CardState.available,
        since: now ?? DateTime.now(),
      );

  AppState copyWith({
    CardState? currentState,
    DateTime? since,
    String? customText,
    bool clearCustomText = false,
    DateTime? lastWriteTs,
    String? lastWriteStatus,
    DateTime? lastSuccessTs,
  }) =>
      AppState(
        currentState: currentState ?? this.currentState,
        since: since ?? this.since,
        customText:
            clearCustomText ? null : (customText ?? this.customText),
        lastWriteTs: lastWriteTs ?? this.lastWriteTs,
        lastWriteStatus: lastWriteStatus ?? this.lastWriteStatus,
        lastSuccessTs: lastSuccessTs ?? this.lastSuccessTs,
      );

  Map<String, Object?> toJson() => {
        'currentState': currentState.name,
        'since': since.toIso8601String(),
        'customText': customText,
        'lastWriteTs': lastWriteTs?.toIso8601String(),
        'lastWriteStatus': lastWriteStatus,
        'lastSuccessTs': lastSuccessTs?.toIso8601String(),
      };

  factory AppState.fromJson(Map<String, Object?> json) => AppState(
        currentState: CardState.values.firstWhere(
          (s) => s.name == json['currentState'],
          orElse: () => CardState.available, // 未来版本降级兼容
        ),
        since: DateTime.parse(json['since'] as String),
        customText: json['customText'] as String?,
        lastWriteTs: json['lastWriteTs'] == null
            ? null
            : DateTime.parse(json['lastWriteTs'] as String),
        lastWriteStatus: json['lastWriteStatus'] as String?,
        lastSuccessTs: json['lastSuccessTs'] == null
            ? null
            : DateTime.parse(json['lastSuccessTs'] as String),
      );
}
