import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_controller.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_submission.dart';
import '../widgets/email_verification_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with AuthSubmissionMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // register() also logs the user in on success.
    final ok = await runSubmission(
      () => ref
          .read(authControllerProvider.notifier)
          .register(_usernameController.text.trim(), _passwordController.text),
    );
    if (ok && mounted) Navigator.of(context).pop(); // Back to AuthGate → home.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthFormScaffold(
      appBar: AppBar(title: const Text('회원가입')),
      formKey: _formKey,
      children: [
        Text(
          '새 계정 만들기',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        UsernameField(controller: _usernameController),
        const SizedBox(height: 16),
        EmailVerificationField(
          emailController: _emailController,
          codeController: _codeController,
        ),
        const SizedBox(height: 16),
        PasswordField(
          controller: _passwordController,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              (v == null || v.length < 4) ? '비밀번호는 4자 이상이어야 합니다.' : null,
        ),
        const SizedBox(height: 16),
        PasswordField(
          controller: _confirmController,
          label: '비밀번호 확인',
          showToggle: false,
          onSubmitted: _submit,
          validator: (v) =>
              (v != _passwordController.text) ? '비밀번호가 일치하지 않습니다.' : null,
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: '회원가입', loading: submitting, onPressed: _submit),
      ],
    );
  }
}
