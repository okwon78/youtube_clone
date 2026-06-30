import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_submission.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with AuthSubmissionMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Submits username/password to the server for a JWT pair. On success the
  /// AuthGate reactively swaps to the home page.
  Future<void> _login() {
    if (!_formKey.currentState!.validate()) return Future.value();
    return runSubmission(
      () => _auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      ),
      connectionError: '로그인에 실패했습니다. 게이트웨이(8080)와 설정을 확인하세요.',
    );
  }

  /// Drives a social (Google/Naver) sign-in via [action] on the controller.
  Future<void> _socialSignIn(Future<void> Function() action) {
    return runSubmission(
      action,
      connectionError: '소셜 로그인에 실패했습니다. 게이트웨이(8080)와 설정을 확인하세요.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthFormScaffold(
      formKey: _formKey,
      children: [
        const Icon(Icons.play_arrow, color: Colors.red, size: 56),
        const SizedBox(height: 8),
        Text(
          'LIVO 로그인',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '아이디와 비밀번호로 로그인하세요.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        UsernameField(controller: _usernameController),
        const SizedBox(height: 16),
        PasswordField(
          controller: _passwordController,
          onSubmitted: _login,
          validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요.' : null,
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: '로그인', loading: submitting, onPressed: _login),
        const SizedBox(height: 8),
        TextButton(
          onPressed: submitting
              ? null
              : () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
          child: const Text('계정이 없으신가요? 회원가입'),
        ),
        const SizedBox(height: 8),
        _OrDivider(theme: theme),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: submitting
              ? null
              : () => _socialSignIn(_auth.loginWithGoogle),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.g_mobiledata, size: 28),
          label: const Text('Google로 로그인'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: submitting
              ? null
              : () => _socialSignIn(_auth.loginWithNaver),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: const Color(0xFF03C75A), // Naver green
            foregroundColor: Colors.white,
          ),
          icon: const Text(
            'N',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          label: const Text('네이버로 로그인'),
        ),
      ],
    );
  }
}

/// The "또는" separator between password and social login.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '또는',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
