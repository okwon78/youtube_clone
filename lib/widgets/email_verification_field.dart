import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Email input paired with a "인증 메일 발송" button. Pressing the button reveals a
/// verification-code input that shows a 10-minute countdown on its right side.
/// When the countdown reaches zero the code input is disabled and a red
/// "입력 시간이 초과되었습니다." message appears beneath it; pressing the button again
/// ("재발송") restarts the flow with a fresh timer.
class EmailVerificationField extends StatefulWidget {
  const EmailVerificationField({
    super.key,
    required this.emailController,
    required this.codeController,
    this.timeout = const Duration(minutes: 10),
  });

  final TextEditingController emailController;
  final TextEditingController codeController;

  /// How long the issued code stays valid. Defaults to 10 minutes.
  final Duration timeout;

  @override
  State<EmailVerificationField> createState() => _EmailVerificationFieldState();
}

class _EmailVerificationFieldState extends State<EmailVerificationField> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _sent = false;

  /// True once a code has been sent and its timer has run out.
  bool get _expired => _sent && _remaining == Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _sendCode() {
    final email = widget.emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('올바른 이메일을 입력하세요.')));
      return;
    }

    // TODO: 백엔드 인증 메일 발송 API를 호출하는 지점.
    FocusScope.of(context).unfocus();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    widget.codeController.clear();
    setState(() {
      _sent = true;
      _remaining = widget.timeout;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = _remaining - const Duration(seconds: 1);
      if (next <= Duration.zero) {
        timer.cancel();
        setState(() => _remaining = Duration.zero);
      } else {
        setState(() => _remaining = next);
      }
    });
  }

  String get _formattedRemaining {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? '올바른 이메일을 입력하세요.' : null,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _sendCode,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 56),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(_sent ? '재발송' : '인증 메일 발송'),
            ),
          ],
        ),
        if (_sent) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.codeController,
            enabled: !_expired,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '인증 번호',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
              border: const OutlineInputBorder(),
              // Red expiry message shown directly beneath the input.
              errorText: _expired ? '입력 시간이 초과되었습니다.' : null,
              // 10-minute countdown pinned to the right of the input.
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  widthFactor: 1,
                  child: Text(
                    _formattedRemaining,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _expired
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
            validator: (v) {
              if (_expired) return '인증 시간이 만료되었습니다. 다시 발송해 주세요.';
              if (v == null || v.trim().isEmpty) return '인증 번호를 입력하세요.';
              return null;
            },
          ),
        ],
      ],
    );
  }
}
