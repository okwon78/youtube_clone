import 'package:flutter/material.dart';

/// Shared layout for the login and register screens: a centered, width-capped,
/// scrollable [Form]. Pages supply only their field/button [children] and an
/// optional [appBar].
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.formKey,
    required this.children,
    this.appBar,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Username input shared by login and register: no autocorrect/suggestions and
/// a non-empty validator.
class UsernameField extends StatelessWidget {
  const UsernameField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      decoration: const InputDecoration(
        labelText: '사용자명',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '사용자명을 입력하세요.' : null,
    );
  }
}

/// Obscured password input with a built-in show/hide toggle. Set [showToggle]
/// to false for confirmation fields that shouldn't reveal the text.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = '비밀번호',
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.validator,
    this.showToggle = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final String? Function(String?)? validator;
  final bool showToggle;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: widget.showToggle
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
      validator: widget.validator,
    );
  }
}

/// A spinner sized to sit inside a full-width button while a request is in
/// flight.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// Full-width primary button that shows a [ButtonSpinner] while [loading] and
/// disables itself so the action can't be triggered twice.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: loading ? const ButtonSpinner() : Text(label),
    );
  }
}
