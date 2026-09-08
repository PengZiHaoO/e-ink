/// 屏2「预览 + 写入」全屏流程页。
///
/// 功能映射（全景 §5）：H2 大预览（WYSIWYG 同源——预览位图 = submit 发送的
/// frameBytes 出自同一次 prepare）· W1-W5 流程态 · 翻转引导 · Mock 失败注入开关。
/// C4 合规：无任何倒计时/秒针元素，时间只以快照文本出现。
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../app/card_preview.dart';
import '../app/deps.dart';
import '../app/theme.dart';
import '../core/hal/card_writer.dart';
import '../core/state/card_state.dart';
import '../core/state/state_machine.dart';
import '../core/write/write_orchestrator.dart';

class WriteScreen extends StatefulWidget {
  final AppDeps deps;
  final CardState targetState;

  const WriteScreen({super.key, required this.deps, required this.targetState});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _textController = TextEditingController();
  Timer? _debounce;
  Timer? _popTimer;

  PreparedCard? _prepared;
  bool _preparing = false;
  bool _writing = false;
  WriteOutcome? _failure;
  bool _celebrating = false;
  String? _validationError;
  bool _messageExpanded = false;

  /// 专注 = 翻转即写入：进屏2 自动开始写（留言默认隐藏）
  bool get _autoSubmitMode => widget.targetState == CardState.focusing;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _popTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_writing) return;
    final text = _textController.text;
    setState(() {
      _preparing = true;
      _failure = null;
      _validationError =
          widget.deps.orchestrator.validateCustomText(text);
    });
    final prepared = await widget.deps.orchestrator.prepare(
      newState: widget.targetState,
      customText: text,
      // T7（P 域）落地后从 UserProfile 读取；M1 占位
      name: 'YOUR NAME',
      title: '',
    );
    if (!mounted) return;
    setState(() {
      _prepared = prepared;
      _preparing = false;
    });
    // 翻转即写入：渲染就绪即发起写入（真机上 NFC 会话等待标签，翻转完成它）
    if (_autoSubmitMode &&
        !_messageExpanded &&
        _textController.text.trim().isEmpty) {
      _submit();
    }
  }

  void _onTextChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _prepare);
  }

  Future<void> _submit() async {
    final prepared = _prepared;
    if (prepared == null || _writing) return;
    setState(() {
      _writing = true;
      _failure = null;
    });
    final outcome = await widget.deps.orchestrator.submit(prepared);
    if (!mounted) return;
    if (outcome.ok) {
      setState(() {
        _writing = false;
        _celebrating = true;
      });
      _popTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _writing = false;
        _failure = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMock = widget.deps.isMock;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.targetState == CardState.namecard ? '名片预览' : '写入卡片',
          style: T.title,
        ),
        backgroundColor: T.paper,
        foregroundColor: T.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: _celebrating ? _buildSuccess() : _buildForm(isMock),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 96, color: T.accent),
          const SizedBox(height: T.s3),
          Text('已更新', style: T.display),
          const SizedBox(height: T.s1),
          Text('卡片现在显示「${widget.targetState.labelZh}」',
              style: T.body.copyWith(color: T.inkSub)),
        ],
      ),
    );
  }

  Widget _buildForm(bool isMock) {
    final prepared = _prepared;
    final canSubmit = prepared != null && !_writing && !_preparing &&
        _validationError == null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.s2, 0, T.s2, T.s2),
          child: Column(
            children: [
              // 翻转引导（专注自动写入态文案不同）
              Text(
                _autoSubmitMode && !_messageExpanded
                    ? '翻转手机，贴住卡片，自动写入中'
                    : (isMock
                        ? '演示模式：点「写入卡片」模拟完整流程'
                        : '翻转手机，贴住卡片'),
                style: T.body.copyWith(color: T.inkSub),
              ),
              if (_autoSubmitMode &&
                  !_messageExpanded &&
                  !_writing &&
                  !_celebrating)
                TextButton(
                  onPressed: () => setState(() => _messageExpanded = true),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(88, T.minTouch),
                    foregroundColor: T.inkSub,
                  ),
                  child: const Text('先加留言？'),
                ),
              const SizedBox(height: T.s2),
              // WYSIWYG 大预览
              Expanded(
                child: Center(
                  child: _preparing && prepared == null
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                              color: T.accent, strokeWidth: 3),
                        )
                      : prepared == null
                          ? const SizedBox.shrink()
                          : CardPreview(bitmap: prepared.bitmap),
                ),
              ),
              const SizedBox(height: T.s2),
              // Mock 失败注入（N3 演示模式专属，真机不显示）
              if (isMock)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('模拟写入失败', style: T.caption),
                    const SizedBox(width: T.s1),
                    Switch(
                      value: _mockFailureOn,
                      onChanged: (v) {
                        setState(() => _mockFailureOn = v);
                        (widget.deps.writer as MockCardWriter).failureRate =
                            v ? 1.0 : 0.0;
                      },
                      activeThumbColor: T.accent,
                    ),
                  ],
                ),
              // 留言输入（S2）：专注自动写入态默认折叠
              if (!_autoSubmitMode || _messageExpanded)
                TextField(
                  controller: _textController,
                  enabled: !_writing,
                  maxLength: StateMachine.maxCustomTextChars,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    labelText: '留言（可选）',
                    helperText: '例如：15:30 后可打扰',
                    errorText: _validationError,
                    counterText:
                        '${_textController.text.trim().length}/${StateMachine.maxCustomTextChars}',
                  ),
                ),
              if (!_autoSubmitMode || _messageExpanded)
                const SizedBox(height: T.s2),
              // 失败面板（W4 文案 + 重试）
              if (_failure != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(T.s2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(T.rButton),
                    border: Border.all(color: T.accent),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: T.accent, size: 24),
                      const SizedBox(width: T.s1),
                      Expanded(
                        child: Text(_failure!.message, style: T.body),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: T.s2),
                SizedBox(
                  width: double.infinity,
                  height: T.minTouch,
                  child: OutlinedButton(
                    onPressed: _submit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: T.ink,
                      side: const BorderSide(color: T.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(T.rButton),
                      ),
                    ),
                    child: const Text('重试'),
                  ),
                ),
                const SizedBox(height: T.s1),
              ],
              // 主行动（A6：全屏唯一实心主按钮；拇指热区）
              SizedBox(
                width: double.infinity,
                height: T.primaryHeight,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: T.accent,
                    foregroundColor: T.onAccent,
                    disabledBackgroundColor: T.line.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(T.rButton),
                    ),
                  ),
                  child: _writing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: T.onAccent, strokeWidth: 2),
                            ),
                            const SizedBox(width: T.s1),
                            Text('写入中…',
                                style: T.title.copyWith(color: T.onAccent)),
                          ],
                        )
                      : Text('写入卡片',
                          style: T.title.copyWith(color: T.onAccent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _mockFailureOn = false;
}
