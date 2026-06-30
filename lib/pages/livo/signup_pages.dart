import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_controller.dart';
import '../../services/auth_api.dart';
import '../../services/social_auth.dart';
import '../../theme/livo_theme.dart';
import '../../widgets/auth_submission.dart';
import '../../widgets/consent_checklist.dart';
import '../../widgets/livo_common.dart';
import 'auth_shell.dart';

/// The two-step social flow for a provider: [signIn] runs the native sign-in to
/// obtain a credential (no session yet) and [complete] exchanges that credential
/// for a session after consent. Null when the provider isn't backend-wired yet
/// (Kakao/Apple/Facebook), so callers can surface a "coming soon" notice.
typedef SocialFlow = ({
  Future<SocialCredential> Function() signIn,
  Future<void> Function(SocialCredential) complete,
});

SocialFlow? _socialFlow(AuthController auth, SocialProvider provider) =>
    switch (provider) {
      SocialProvider.google => (
        signIn: auth.signInWithGoogle,
        complete: auth.completeGoogleLogin,
      ),
      SocialProvider.naver => (
        signIn: auth.signInWithNaver,
        complete: auth.completeNaverLogin,
      ),
      _ => null,
    };

/// Shared social signup orchestration for the login and SNS-signup screens:
/// run the provider's native sign-in (busy-guarded), then push the
/// [SocialConsentPage] which records consent and exchanges the token for a
/// session. Returns true once a session is established; false if the provider
/// isn't supported, the user cancels, or sign-in fails. Backed-out native
/// dialogs are handled silently by [AuthSubmissionMixin].
mixin SocialConsentLauncher<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, AuthSubmissionMixin<T> {
  static const _socialError = '소셜 로그인에 실패했습니다. 게이트웨이(8080)와 설정을 확인하세요.';

  Future<bool> launchSocialSignup(SocialProvider provider) async {
    final flow = _socialFlow(
      ref.read(authControllerProvider.notifier),
      provider,
    );
    if (flow == null) {
      showError('${provider.koreanName} 로그인은 곧 지원할 예정이에요');
      return false;
    }

    // Step 1: native sign-in to obtain the provider credential.
    SocialCredential? credential;
    final signedIn = await runSubmission(
      () async => credential = await flow.signIn(),
      connectionError: _socialError,
    );
    final cred = credential;
    if (!signedIn || cred == null || !mounted) return false;

    // Step 2: collect consent; the page exchanges the token on acceptance.
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SocialConsentPage(
          provider: provider,
          credential: cred,
          onComplete: () => flow.complete(cred),
        ),
      ),
    );
    return done == true;
  }
}

/// Signup landing — choose email vs. SNS signup. Both paths are visual-only
/// for now (the backend doesn't expose registration to these screens yet).
class SignupLandingPage extends StatelessWidget {
  const SignupLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const perks = <(IconData, String)>[
      (Icons.sensors, '실시간 라이브 시청 & 채팅 참여'),
      (Icons.favorite_border, '좋아하는 BJ 팔로우 & 알림'),
      (Icons.monetization_on_outlined, '포인트 충전으로 후원하기'),
    ];
    return AuthScreenShell(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Center(child: LivoLogo(size: 40)),
          const SizedBox(height: 22),
          const Text(
            'LIVO 통합 회원가입으로\n라이브 · 클립 · 후원을 한 번에 이용하세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LivoColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.45,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 28),
          for (final (icon, label) in perks) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: LivoColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: LivoColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: LivoColors.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 18),
          PillButton(
            full: true,
            variant: PillVariant.white,
            onPressed: () async {
              // SignupEmailPage 가 가입+로그인에 성공하면 true 를 돌려준다. 그걸 그대로
              // 상위(로그인 화면 → livo_shell)로 올려 보내 로그인 완료 흐름에 합류시킨다.
              final done = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const SignupEmailPage()),
              );
              if (done == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('이메일로 가입하기'),
          ),
          const SizedBox(height: 12),
          PillButton(
            full: true,
            variant: PillVariant.outline,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SignupSocialPage())),
            child: const Text('SNS 계정으로 가입하기'),
          ),
          const SizedBox(height: 28),
          Center(
            child: Wrap(
              children: [
                const Text(
                  '이미 계정이 있으신가요? ',
                  style: TextStyle(
                    color: LivoColors.sub,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    '로그인하기',
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/// Dedicated SNS signup page — one full-width button per provider. Google/Naver
/// run the real consent + sign-in flow; the rest are not yet backend-wired.
class SignupSocialPage extends ConsumerStatefulWidget {
  const SignupSocialPage({super.key});

  @override
  ConsumerState<SignupSocialPage> createState() => _SignupSocialPageState();
}

class _SignupSocialPageState extends ConsumerState<SignupSocialPage>
    with AuthSubmissionMixin, SocialConsentLauncher {
  Future<void> _onProviderTap(SocialProvider provider) async {
    // launchSocialSignup surfaces a "coming soon" notice for unwired providers
    // (Kakao/Apple/Facebook) and returns false, so we just bubble real success.
    final done = await launchSocialSignup(provider);
    if (done && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      onBack: submitting ? null : () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Center(child: LivoLogo(size: 38)),
          const SizedBox(height: 18),
          const Text(
            'SNS 계정으로 간편 가입',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LivoColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '3초 만에 LIVO를 시작하세요',
            textAlign: TextAlign.center,
            style: TextStyle(color: LivoColors.sub, fontSize: 14),
          ),
          const SizedBox(height: 32),
          for (final p in SocialProvider.values) ...[
            _SocialSignupButton(
              provider: p,
              onTap: submitting ? null : () => _onProviderTap(p),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 14),
          Center(
            child: Wrap(
              children: [
                const Text(
                  '이미 계정이 있으신가요? ',
                  style: TextStyle(
                    color: LivoColors.sub,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).popUntil((r) => r.isFirst || r.settings.name == null),
                  child: const Text(
                    '로그인하기',
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SocialSignupButton extends StatelessWidget {
  const _SocialSignupButton({required this.provider, required this.onTap});

  final SocialProvider provider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final outlined =
        provider == SocialProvider.google || provider == SocialProvider.apple;
    return Material(
      color: provider.bg,
      shape: StadiumBorder(
        side: outlined
            ? const BorderSide(color: Color(0x1A000000))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(left: 20, child: provider.glyph(size: 26)),
              Text(
                provider.startLabel,
                style: TextStyle(
                  color: provider.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consent step for social signup/login. Shown after the provider's native
/// sign-in succeeds (so the user's email/nickname are known) and before the
/// account is linked: the user reviews who they're signing up as and accepts the
/// same server-driven consents as email signup. On acceptance [onComplete]
/// exchanges the provider token for a session and the page pops `true`.
///
/// Note: the required consents are enforced client-side here; the `/oauth/*`
/// exchange endpoints don't yet accept consent flags, so (unlike email signup's
/// `/register`) the choices aren't recorded server-side for social accounts.
class SocialConsentPage extends ConsumerStatefulWidget {
  const SocialConsentPage({
    super.key,
    required this.provider,
    required this.credential,
    required this.onComplete,
  });

  final SocialProvider provider;
  final SocialCredential credential;

  /// Exchanges [credential] for a session. Run when the user accepts.
  final Future<void> Function() onComplete;

  @override
  ConsumerState<SocialConsentPage> createState() => _SocialConsentPageState();
}

class _SocialConsentPageState extends ConsumerState<SocialConsentPage>
    with AuthSubmissionMixin {
  /// Playful auto-generated nickname parts, used when the provider didn't hand
  /// back a usable display name.
  static const _adjectives = [
    '비범한',
    '잔잔한',
    '용감한',
    '따뜻한',
    '엉뚱한',
    '반짝이는',
    '느긋한',
    '씩씩한',
  ];
  static const _nouns = ['청춘', '여행자', '드러머', '별빛', '산책러', '라이브', '파도', '고양이'];

  bool _consentsOk = false;

  late final String _nickname;
  late final bool _nicknameAuto;

  @override
  void initState() {
    super.initState();
    final (nick, auto) = _resolveNickname();
    _nickname = nick;
    _nicknameAuto = auto;
  }

  /// The user's email, taken from the provider credential (some providers put it
  /// in [SocialCredential.displayName] instead of [SocialCredential.email]).
  String? get _email {
    final email = widget.credential.email;
    if (email != null && email.contains('@')) return email;
    final name = widget.credential.displayName;
    if (name != null && name.contains('@')) return name;
    return null;
  }

  /// The display nickname and whether it was auto-generated. Uses the provider's
  /// display name when it's a real (non-email) name; otherwise derives a stable
  /// playful nickname from the email so re-entry shows the same one.
  (String, bool) _resolveNickname() {
    final name = widget.credential.displayName;
    if (name != null && name.trim().isNotEmpty && !name.contains('@')) {
      return (name.trim(), false);
    }
    final seed = (_email ?? widget.credential.token).hashCode.abs();
    final adj = _adjectives[seed % _adjectives.length];
    final noun = _nouns[(seed ~/ _adjectives.length) % _nouns.length];
    return ('$adj$noun', true);
  }

  Future<void> _submit() async {
    if (!_consentsOk || submitting) return;
    final ok = await runSubmission(
      widget.onComplete,
      connectionError: '소셜 로그인에 실패했습니다. 게이트웨이(8080)와 설정을 확인하세요.',
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return AuthScreenShell(
      onBack: submitting ? null : () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 36),
          const Center(child: LivoLogo(size: 40)),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProviderAvatar(provider: provider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${provider.koreanName} 계정으로 회원가입을 진행합니다.',
                      style: const TextStyle(
                        color: LivoColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '약관 동의 후 LIVO 회원으로 가입되며, 이후 간편 로그인이 가능합니다.',
                      style: TextStyle(
                        color: LivoColors.sub,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _InfoRow(label: '이메일', value: _email ?? '제공되지 않음'),
          const SizedBox(height: 4),
          _InfoRow(
            label: '닉네임',
            value: _nickname,
            hint: _nicknameAuto ? '닉네임이 자동 생성되었습니다.' : null,
          ),
          const SizedBox(height: 26),
          ConsentChecklist(
            onChanged: (state) =>
                setState(() => _consentsOk = state.allRequiredChecked),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  full: true,
                  variant: PillVariant.outline,
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PillButton(
                  full: true,
                  disabled: !_consentsOk || submitting,
                  onPressed: _submit,
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('가입 완료하기'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// Circular brand badge for the provider, shown beside the signup blurb.
class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({required this.provider});

  final SocialProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: provider.bg,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Center(child: provider.glyph(size: 24)),
    );
  }
}

/// A "label : value" row (with an optional hint line) for the account summary.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                color: LivoColors.sub,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: LivoColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      hint!,
                      style: const TextStyle(
                        color: LivoColors.faint,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Email signup — email verification, password rules, and consents. The form
/// is fully interactive but completion is visual-only for now.
class SignupEmailPage extends ConsumerStatefulWidget {
  const SignupEmailPage({super.key});

  @override
  ConsumerState<SignupEmailPage> createState() => _SignupEmailPageState();
}

class _SignupEmailPageState extends ConsumerState<SignupEmailPage> {
  /// How long a verification code stays valid, in seconds (08:00).
  static const _codeTtl = 8 * 60;

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _pw = TextEditingController();
  bool _sent = false;
  bool _sending = false;
  bool _verifying = false;
  bool _submitting = false;
  bool _codeVerified = false;

  /// Latest snapshot from the [ConsentChecklist]: whether all required consents
  /// are checked (gates submit) and the per-key checked map (recorded on signup).
  bool _consentsOk = false;
  Map<String, bool> _consentChecked = const {};

  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _email.addListener(() => setState(() {}));
    _code.addListener(() {
      // Editing the code after it was verified invalidates the verification.
      if (_codeVerified) _codeVerified = false;
      setState(() {});
    });
    _pw.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _pw.dispose();
    super.dispose();
  }

  AuthApi get _api => ref.read(authApiProvider);

  /// Asks the server to (re)send a verification code, then starts the countdown
  /// from the server-provided lifetime. On failure the form stays unchanged and
  /// the error is surfaced.
  Future<void> _sendCode() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final expiresIn = await _api.requestEmailVerification(_email.text.trim());
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _sent = true;
        _codeVerified = false;
        _code.clear();
        _remaining = expiresIn > 0 ? expiresIn : _codeTtl;
      });
      _startTimer();
      _showSnack('인증 이메일이 발송되었습니다.');
    } on AuthApiException catch (e) {
      _showSnack(e.message);
    } catch (e, st) {
      debugPrint('[signup] 인증 메일 발송 실패: $e\n$st');
      _showSnack('인증 메일 발송에 실패했습니다. 게이트웨이(8080)를 확인하세요.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Drives the verification-code countdown, ticking [_remaining] down to 0.
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _timerLabel {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Submits the entered code to the auth server. Marks the email verified only
  /// when the server confirms it; a wrong/expired code surfaces the server's
  /// message and leaves the form unverified.
  Future<void> _verifyCode() async {
    if (_verifying || _codeVerified) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      await _api.confirmEmailVerification(_email.text.trim(), _code.text);
      if (!mounted) return;
      setState(() {
        _codeVerified = true;
        _timer?.cancel();
      });
      _showSnack('인증번호가 확인되었습니다.');
    } on AuthApiException catch (e) {
      _showSnack(e.message);
    } catch (e, st) {
      debugPrint('[signup] 인증번호 확인 실패: $e\n$st');
      _showSnack('인증번호 확인에 실패했습니다. 게이트웨이(8080)를 확인하세요.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  bool get _emailOk => _email.text.contains('@');
  bool get _codeOk => _code.text.length == 6 && _remaining > 0;

  /// The confirm button is enabled while there's a 6-digit code, time remaining,
  /// and no verification already in flight or completed.
  bool get _canVerifyCode => _codeOk && !_verifying && !_codeVerified;
  bool get _pwLenOk => _pw.text.length >= 10;
  bool get _pwMixOk =>
      RegExp(r'[a-zA-Z]').hasMatch(_pw.text) &&
      RegExp(r'[0-9]').hasMatch(_pw.text) &&
      RegExp(r'[^a-zA-Z0-9]').hasMatch(_pw.text);

  /// The password must not be identical to the email (id). Compared
  /// case-insensitively and trimmed; treated as OK while either field is empty
  /// so the rule only flags an actual match.
  bool get _pwNotEmail {
    final pw = _pw.text.trim();
    final email = _email.text.trim();
    if (pw.isEmpty || email.isEmpty) return true;
    return pw.toLowerCase() != email.toLowerCase();
  }

  bool get _valid =>
      _emailOk &&
      _sent &&
      _codeVerified &&
      _pwLenOk &&
      _pwMixOk &&
      _pwNotEmail &&
      _consentsOk;

  /// Creates the account with the checked consents, then (via the controller)
  /// logs the user in. On success we pop `true` so the signup/login chain can
  /// finish; failures surface the server's message and leave the form intact.
  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            _email.text.trim(),
            _pw.text,
            agreedAge14: _consentChecked['age14'] ?? false,
            agreedTerms: _consentChecked['terms'] ?? false,
            agreedPrivacy: _consentChecked['privacy'] ?? false,
            agreedMarketing: _consentChecked['marketing'] ?? false,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthApiException catch (e) {
      _showSnack(e.message);
    } catch (e, st) {
      debugPrint('[signup] 회원가입 실패: $e\n$st');
      _showSnack('회원가입에 실패했습니다. 게이트웨이(8080)를 확인하세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 36),
          const Center(child: LivoLogo(size: 36)),
          const SizedBox(height: 36),
          LivoUnderlineField(
            controller: _email,
            hint: '이메일 주소를 입력해 주세요.',
            keyboardType: TextInputType.emailAddress,
            trailing: _VerifyButton(
              sent: _sent,
              enabled: _emailOk && !_sending,
              busy: _sending,
              onTap: _sendCode,
            ),
          ),
          if (_sent) ...[
            const SizedBox(height: 18),
            LivoUnderlineField(
              controller: _code,
              hint: '인증번호 6자리를 입력해 주세요.',
              enabled: !_codeVerified,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              trailing: _codeVerified
                  ? const _CodeVerifiedBadge()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            _remaining > 0 ? _timerLabel : '시간 만료',
                            style: const TextStyle(
                              color: LivoColors.live,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CodeConfirmButton(
                          enabled: _canVerifyCode,
                          busy: _verifying,
                          onTap: _verifyCode,
                        ),
                      ],
                    ),
            ),
            if (_remaining == 0 && !_codeVerified)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '인증 시간이 만료되었어요. 이메일을 재발송해 주세요.',
                  style: TextStyle(
                    color: LivoColors.live,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 18),
          LivoUnderlineField(
            controller: _pw,
            hint: '비밀번호를 입력해 주세요.',
            obscure: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Rule(ok: _pwLenOk, text: '영문, 숫자, 특수문자 포함 10자 이상'),
              _Rule(ok: _pwMixOk, text: '영문·숫자·특수문자 조합'),
              _Rule(ok: _pwNotEmail, text: '아이디(이메일)와 다른 비밀번호'),
            ],
          ),
          const SizedBox(height: 26),
          ConsentChecklist(
            onChanged: (state) => setState(() {
              _consentsOk = state.allRequiredChecked;
              _consentChecked = state.checked;
            }),
          ),
          const SizedBox(height: 24),
          PillButton(
            full: true,
            disabled: !_valid || _submitting,
            onPressed: _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('가입 완료하기'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.sent,
    required this.enabled,
    required this.onTap,
    this.busy = false,
  });

  final bool sent;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = sent
        ? LivoColors.surface2
        : (enabled ? LivoColors.accent : LivoColors.surface2);
    final fg = sent
        ? LivoColors.accent
        : (enabled ? Colors.white : LivoColors.faint);
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : Text(
                  sent ? '재발송' : '인증 메일 발송',
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Compact "확인" button shown in the verification-code field, used to submit
/// the entered code to the server for checking.
class _CodeConfirmButton extends StatelessWidget {
  const _CodeConfirmButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? LivoColors.accent : LivoColors.surface2;
    final fg = enabled ? Colors.white : LivoColors.faint;
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '확인',
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// "✓ 인증 완료" badge that replaces the timer + confirm button once the code
/// has been verified.
class _CodeVerifiedBadge extends StatelessWidget {
  const _CodeVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: LivoColors.naver),
          SizedBox(width: 4),
          Text(
            '인증 완료',
            style: TextStyle(
              color: LivoColors.naver,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = ok ? LivoColors.naver : LivoColors.faint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
