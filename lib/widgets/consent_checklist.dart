import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_controller.dart';
import '../services/auth_api.dart';
import '../theme/livo_theme.dart';

/// The current state of a [ConsentChecklist]: whether every *required* item is
/// checked (the gate for proceeding) and the per-key checked map (so the caller
/// can record exactly what was agreed to).
typedef ConsentState = ({bool allRequiredChecked, Map<String, bool> checked});

/// Server-driven signup consent list, shared by the email- and social-signup
/// screens. Loads the items from the auth server (`GET /consents/signup`),
/// falling back to [ConsentItem.fallback] when it can't be reached, and renders
/// a "전체 동의" master row plus one row per item. Reports selection changes via
/// [onChanged] so the host page can gate its submit button and read back the
/// checked map. Every item starts unchecked.
class ConsentChecklist extends ConsumerStatefulWidget {
  const ConsentChecklist({super.key, required this.onChanged});

  /// Called after the list loads and on every toggle with the latest state.
  final ValueChanged<ConsentState> onChanged;

  @override
  ConsumerState<ConsentChecklist> createState() => _ConsentChecklistState();
}

class _ConsentChecklistState extends ConsumerState<ConsentChecklist> {
  /// Consent items served by the auth server (null while still loading), and the
  /// per-key checked state keyed by [ConsentItem.key].
  List<ConsentItem>? _consents;
  final Map<String, bool> _checked = {};

  AuthApi get _api => ref.read(authApiProvider);

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  /// Loads the consent list from the auth server (the source of truth). On
  /// failure we fall back to [ConsentItem.fallback] so signup still works
  /// offline. Every key starts unchecked.
  Future<void> _loadConsents() async {
    try {
      final items = await _api.fetchSignupConsents();
      if (!mounted) return;
      setState(() => _setConsents(items));
    } catch (e, st) {
      debugPrint('[consent] 동의 항목 로드 실패, 기본값 사용: $e\n$st');
      if (!mounted) return;
      setState(() => _setConsents(ConsentItem.fallback));
    }
    _notify();
  }

  /// Installs [items] as the consent list, seeding each key's checked state to
  /// false (preserving any already-checked values on a reload).
  void _setConsents(List<ConsentItem> items) {
    _consents = items;
    for (final c in items) {
      _checked.putIfAbsent(c.key, () => false);
    }
  }

  /// Whether every required consent is checked. False until the list loads.
  bool get _allRequired {
    final items = _consents;
    return items != null &&
        items.where((c) => c.required).every((c) => _checked[c.key] == true);
  }

  /// Whether every consent — required and optional — is checked (drives the
  /// "전체 동의" master checkbox).
  bool get _allAgree {
    final items = _consents;
    return items != null &&
        items.isNotEmpty &&
        items.every((c) => _checked[c.key] == true);
  }

  void _notify() =>
      widget.onChanged((allRequiredChecked: _allRequired, checked: _checked));

  void _toggle(String key) {
    setState(() => _checked[key] = !(_checked[key] ?? false));
    _notify();
  }

  void _toggleAll() {
    final items = _consents;
    if (items == null) return;
    final v = !_allAgree;
    setState(() {
      for (final c in items) {
        _checked[c.key] = v;
      }
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final items = _consents;
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConsentRow(
          value: _allAgree,
          bold: true,
          label: '전체 동의',
          onTap: _toggleAll,
        ),
        const Divider(height: 9, thickness: 0.5, color: LivoColors.line),
        for (final c in items)
          _ConsentRow(
            value: _checked[c.key] ?? false,
            label: c.label,
            link: c.link.isNotEmpty,
            onTap: () => _toggle(c.key),
          ),
      ],
    );
  }
}

/// A single tappable consent row: a square check box, the (server-provided)
/// label, and an optional "보기" link affordance for items with full text.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.label,
    required this.onTap,
    this.bold = false,
    this.link = false,
  });

  final bool value;
  final String label;
  final VoidCallback onTap;
  final bool bold;
  final bool link;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? LivoColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: value
                    ? null
                    : Border.all(color: LivoColors.faint, width: 1.5),
              ),
              child: value
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: bold ? LivoColors.text : LivoColors.sub,
                  fontSize: bold ? 16 : 14.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (link)
              const Text(
                '보기',
                style: TextStyle(
                  color: LivoColors.faint,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
