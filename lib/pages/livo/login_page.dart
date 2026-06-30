import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../../theme/livo_theme.dart';
import '../../widgets/auth_submission.dart';
import '../../widgets/livo_common.dart';
import 'auth_shell.dart';
import 'signup_pages.dart';

/// LIVO login. Email/password and Google/Naver are wired to the real auth
/// backend; Kakao/Apple/Facebook are not yet supported server-side and surface
/// a "coming soon" notice. Pops with `true` once a session is established so
/// the shell can switch to the MY tab.
class LivoLoginPage extends ConsumerStatefulWidget {
  const LivoLoginPage({super.key});

  @override
  ConsumerState<LivoLoginPage> createState() => _LivoLoginPageState();
}

class _LivoLoginPageState extends ConsumerState<LivoLoginPage>
    with AuthSubmissionMixin, SocialConsentLauncher {
  final _email = TextEditingController();
  final _pw = TextEditingController();

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _email.addListener(_refresh);
    _pw.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  bool get _canSubmit => _email.text.contains('@') && _pw.text.length >= 4;

  Future<void> _login() async {
    if (!_canSubmit) return;
    final ok = await runSubmission(
      () => _auth.login(_email.text.trim(), _pw.text),
      connectionError: '로그인에 실패했습니다. 게이트웨이(8080)와 설정을 확인하세요.',
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  /// Social login goes through the consent step: native sign-in, then the
  /// [SocialConsentPage] which records consent and exchanges the token. Unwired
  /// providers surface a "coming soon" notice from the launcher.
  Future<void> _social(SocialProvider provider) async {
    final ok = await launchSocialSignup(provider);
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      onClose: submitting ? null : () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 44),
          const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [LivoLogo(size: 40), SizedBox(width: 8), _BetaTag()],
            ),
          ),
          const SizedBox(height: 56),
          LivoUnderlineField(
            controller: _email,
            hint: '이메일 주소를 입력해 주세요.',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          LivoUnderlineField(
            controller: _pw,
            hint: '비밀번호를 입력해 주세요.',
            obscure: true,
            onSubmitted: _login,
          ),
          const SizedBox(height: 28),
          PillButton(
            full: true,
            disabled: !_canSubmit || submitting,
            onPressed: _login,
            child: submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text('로그인하기'),
          ),
          const SizedBox(height: 18),
          const _HelpLinks(),
          const SizedBox(height: 44),
          const Center(
            child: Text(
              'SNS 계정으로 로그인하기',
              style: TextStyle(
                color: LivoColors.sub,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final p in SocialProvider.values) ...[
                SocialCircleButton(
                  provider: p,
                  recent: p == SocialProvider.naver,
                  onTap: submitting ? null : () => _social(p),
                ),
                if (p != SocialProvider.values.last) const SizedBox(width: 14),
              ],
            ],
          ),
          const SizedBox(height: 44),
          Center(
            child: Wrap(
              children: [
                const Text(
                  '아직 LIVO 회원이 아니신가요? ',
                  style: TextStyle(
                    color: LivoColors.sub,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: submitting ? null : _openSignup,
                  child: const Text(
                    '회원가입하기',
                    style: TextStyle(
                      color: LivoColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _openSignup() async {
    final done = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const SignupLandingPage()));
    // Signup is visual-only today; if a future flow returns success, bubble it.
    if (done == true && mounted) Navigator.of(context).pop(true);
  }
}

class _BetaTag extends StatelessWidget {
  const _BetaTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: LivoColors.surface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'BETA',
        style: TextStyle(
          color: LivoColors.sub,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HelpLinks extends StatelessWidget {
  const _HelpLinks();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: LivoColors.sub,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('이메일(아이디) 찾기', style: style),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('|', style: TextStyle(color: LivoColors.line)),
        ),
        Text('비밀번호 재설정', style: style),
      ],
    );
  }
}
