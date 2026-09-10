/// 屏2「预览 + 写入」全屏流程页（文案走 l10n；W4 错误文案本地化）。
///
/// C1 同源：预览位图 = submit 发送字节（同一次 prepare 产物）。
/// 专注 = 翻转即写入：进屏自动发起写入（留言默认折叠）。
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../app/card_preview.dart';
import '../app/deps.dart';
import '../app/theme.dart';
import '../core/hal/card_writer.dart';
import '../core/state/card_state.dart';
import '../core/state/state_machine.dart';
import '../core/hal/qr_bitmap.dart';
import '../core/write/write_orchestrator.dart';
import '../l10n/app_localizations.dart';

/// W4 · 错误文案本地化映射（kind → 当前语言文案）
String errorCopy(WriteErrorKind kind, AppLocalizations l) => switch (kind) {
      WriteErrorKind.timeout => l.errTimeout,
      WriteErrorKind.capacity => l.errCapacity,
      WriteErrorKind.readOnly => l.errReadOnly,
      WriteErrorKind.notNdef => l.errNotNdef,
      WriteErrorKind.canceled => l.errCanceled,
      WriteErrorKind.nfcDisabled => l.errNfcDisabled,
      WriteErrorKind.tagLost => l.errTagLost,
      WriteErrorKind.unknown => l.errUnknown,
    };

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
  bool _validationError = false;
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
          widget.deps.orchestrator.validateCustomText(text) != null;
    });
    final up = widget.deps.userProfile;
    final prepared = await widget.deps.orchestrator.prepare(
      newState: widget.targetState,
      customText: text,
      name: up.isComplete ? up.name : null,
      title: up.title.isEmpty ? null : up.title,
      qrBitmap: renderQrBitmap(up.qrContent, scale: 3),
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
    final l = AppLocalizations.of(context);
    final zh = widget.deps.isZh;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.targetState == CardState.namecard
              ? l.writeTitleCard
              : l.writeTitle,
          style: T.title,
        ),
        backgroundColor: T.paper,
        foregroundColor: T.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: _celebrating
            ? _buildSuccess(l, zh)
            : _buildForm(l, widget.deps.isMock),
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations l, bool zh) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 96, color: T.accent),
          const SizedBox(height: T.s3),
          Text(l.updated, style: T.display),
          const SizedBox(height: T.s1),
          Text(l.updatedSub(widget.targetState.label(zh)),
              style: T.body.copyWith(color: T.inkSub)),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations l, bool isMock) {
    final prepared = _prepared;
    final canSubmit = prepared != null &&
        !_writing &&
        !_preparing &&
        !_validationError;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.s2, 0, T.s2, T.s2),
          child: Column(
            children: [
              Text(
                _autoSubmitMode && !_messageExpanded
                    ? l.guideAuto
                    : (isMock ? l.guideMock : l.guideManual),
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
                  child: Text(l.addMessageFirst),
                ),
              const SizedBox(height: T.s2),
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
              // 编辑器诚实：画布规格 meta（等宽）
              Text(
                '${widget.deps.profile.canvasW}×${widget.deps.profile.canvasH} · 1-BIT · RLE',
                style: T.meta,
              ),
              const SizedBox(height: T.s2),
              if (isMock)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.mockFailToggle.toUpperCase(), style: T.micro),
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
              if (!_autoSubmitMode || _messageExpanded)
                TextField(
                  controller: _textController,
                  enabled: !_writing,
                  maxLength: StateMachine.maxCustomTextChars,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    labelText: l.messageLabel,
                    helperText: l.messageHelper,
                    errorText: _validationError
                        ? l.messageTooLong(StateMachine.maxCustomTextChars)
                        : null,
                    counterText:
                        '${_textController.text.trim().length}/${StateMachine.maxCustomTextChars}',
                  ),
                ),
              if (!_autoSubmitMode || _messageExpanded)
                const SizedBox(height: T.s2),
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
                      const Icon(Icons.error_outline,
                          color: T.accent, size: 24),
                      const SizedBox(width: T.s1),
                      Expanded(
                        child: Text(
                            errorCopy(_failure!.error!, l),
                            style: T.body),
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
                      side: const BorderSide(color: T.hairline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(T.rButton),
                      ),
                    ),
                    child: Text(l.retry),
                  ),
                ),
                const SizedBox(height: T.s1),
              ],
              SizedBox(
                width: double.infinity,
                height: T.primaryHeight,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: T.accent,
                    foregroundColor: T.onAccent,
                    disabledBackgroundColor: T.hairline,
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
                            Text(l.writing,
                                style: T.title.copyWith(color: T.onAccent)),
                          ],
                        )
                      : Text(l.writeButton,
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
