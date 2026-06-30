import 'package:flutter/material.dart';

import '../../theme/livo_theme.dart';

/// Shared chrome for the auth screens: a top bar with optional back / close
/// circular buttons over a scrollable body. Mirrors the design's `ScreenShell`.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.child,
    this.onBack,
    this.onClose,
  });

  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: LivoColors.bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14, topInset + 8, 14, 0),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    _CircleButton(icon: Icons.chevron_left, onTap: onBack!)
                  else
                    const SizedBox(width: 40),
                  if (onClose != null)
                    _CircleButton(icon: Icons.close, onTap: onClose!)
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(side: BorderSide(color: LivoColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: LivoColors.text),
        ),
      ),
    );
  }
}
