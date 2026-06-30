import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/broadcast.dart';
import '../theme/livo_theme.dart';

/// Network image with surface-colored placeholder + graceful error fallback,
/// so the picsum thumbnails never flash a broken-image glyph.
class LivoImage extends StatelessWidget {
  const LivoImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(color: LivoColors.surface2),
      errorBuilder: (context, error, stack) => const ColoredBox(
        color: LivoColors.surface2,
        child: Center(
          child: Icon(Icons.image_outlined, color: LivoColors.faint, size: 28),
        ),
      ),
    );
  }
}

/// The LIVO wordmark: a live-red dot wrapped in a soft violet ring + "LIVO".
class LivoLogo extends StatelessWidget {
  const LivoLogo({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.34,
          height: size * 0.34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LivoColors.live,
            boxShadow: [
              BoxShadow(color: LivoColors.accentSoft, spreadRadius: size * 0.1),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          'LIVO',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: LivoColors.text,
          ),
        ),
      ],
    );
  }
}

/// Red "● LIVE" badge overlaid on thumbnails.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LivoColors.live,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: small ? 10 : 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// "👁 N" viewer count pill used on cards and ranking rows.
class ViewPill extends StatelessWidget {
  const ViewPill({super.key, required this.viewers});

  final int viewers;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.visibility_outlined, size: 15, color: LivoColors.sub),
        const SizedBox(width: 4),
        Text(
          fmtViewers(viewers),
          style: const TextStyle(
            color: LivoColors.sub,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

enum PillVariant { primary, white, outline, live }

/// Rounded full-width-capable button matching the design's `PillButton`.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = PillVariant.primary,
    this.full = false,
    this.disabled = false,
    this.height = 52,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final bool full;
  final bool disabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    BorderSide side = BorderSide.none;
    switch (variant) {
      case PillVariant.primary:
        bg = disabled ? LivoColors.surface2 : LivoColors.accent;
        fg = disabled ? LivoColors.faint : Colors.white;
      case PillVariant.white:
        bg = Colors.white;
        fg = Colors.black;
      case PillVariant.outline:
        bg = Colors.transparent;
        fg = LivoColors.text;
        side = const BorderSide(color: LivoColors.line, width: 1.5);
      case PillVariant.live:
        bg = LivoColors.live;
        fg = Colors.white;
    }

    Widget content = DefaultTextStyle.merge(
      style: TextStyle(
        color: fg,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: fg, size: 20),
        child: child,
      ),
    );
    if (!full) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: content,
      );
    }

    final button = Material(
      color: bg,
      shape: StadiumBorder(side: side),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        child: SizedBox(
          height: height,
          child: Center(child: content),
        ),
      ),
    );
    return full ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Underlined dark text field used across the auth screens.
class LivoUnderlineField extends StatefulWidget {
  const LivoUnderlineField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.trailing,
    this.onSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final VoidCallback? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<LivoUnderlineField> createState() => _LivoUnderlineFieldState();
}

class _LivoUnderlineFieldState extends State<LivoUnderlineField> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: LivoColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: widget.enabled,
              obscureText: widget.obscure && !_show,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              cursorColor: LivoColors.accent,
              style: TextStyle(
                color: widget.enabled ? LivoColors.text : LivoColors.sub,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: LivoColors.faint,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (widget.obscure)
            IconButton(
              onPressed: () => setState(() => _show = !_show),
              icon: Icon(
                _show
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: LivoColors.sub,
              ),
            ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

/// The five supported social providers.
enum SocialProvider { kakao, naver, google, apple, facebook }

extension SocialProviderUi on SocialProvider {
  Color get bg => switch (this) {
    SocialProvider.kakao => LivoColors.kakao,
    SocialProvider.naver => LivoColors.naver,
    SocialProvider.google => Colors.white,
    SocialProvider.apple => Colors.white,
    SocialProvider.facebook => LivoColors.facebook,
  };

  Color get fg => switch (this) {
    SocialProvider.kakao => const Color(0xFF3C1E1E),
    SocialProvider.naver => Colors.white,
    SocialProvider.google => const Color(0xFF1F1F1F),
    SocialProvider.apple => Colors.black,
    SocialProvider.facebook => Colors.white,
  };

  /// The provider's Korean display name, e.g. "구글", "네이버".
  String get koreanName => switch (this) {
    SocialProvider.kakao => '카카오',
    SocialProvider.naver => '네이버',
    SocialProvider.google => '구글',
    SocialProvider.apple => 'Apple',
    SocialProvider.facebook => '페이스북',
  };

  String get startLabel => switch (this) {
    SocialProvider.kakao => '카카오로 시작하기',
    SocialProvider.naver => '네이버로 시작하기',
    SocialProvider.google => 'Google로 시작하기',
    SocialProvider.apple => 'Apple로 시작하기',
    SocialProvider.facebook => 'Facebook으로 시작하기',
  };

  /// The brand glyph drawn inside the circular / leading badge.
  Widget glyph({double size = 26}) {
    switch (this) {
      case SocialProvider.kakao:
        return Icon(Icons.chat_bubble, size: size * 0.8, color: fg);
      case SocialProvider.apple:
        return Icon(Icons.apple, size: size, color: fg);
      case SocialProvider.naver:
        return _BrandLetter('N', size: size, color: fg);
      case SocialProvider.google:
        return _BrandLetter('G', size: size, color: const Color(0xFF4285F4));
      case SocialProvider.facebook:
        return _BrandLetter('f', size: size, color: fg);
    }
  }
}

class _BrandLetter extends StatelessWidget {
  const _BrandLetter(this.letter, {required this.size, required this.color});

  final String letter;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      letter,
      style: TextStyle(
        fontSize: size * 0.82,
        height: 1,
        fontWeight: FontWeight.w900,
        color: color,
      ),
    );
  }
}

/// Circular social provider button (login screen row), with optional
/// "최근 로그인" tooltip bubble above.
class SocialCircleButton extends StatelessWidget {
  const SocialCircleButton({
    super.key,
    required this.provider,
    this.size = 56,
    this.recent = false,
    this.onTap,
  });

  final SocialProvider provider;
  final double size;
  final bool recent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recent)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: LivoColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '최근 로그인',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Material(
          color: provider.bg,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(child: provider.glyph(size: size * 0.46)),
            ),
          ),
        ),
      ],
    );
  }
}

/// App header: logo on the left, bell + search on the right. Scrolls with the
/// content (not pinned), matching the mockup. Accounts for the status bar.
class LivoAppHeader extends StatelessWidget {
  const LivoAppHeader({super.key, this.onSearch});

  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: LivoColors.bg,
      padding: EdgeInsets.fromLTRB(18, top + 10, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const LivoLogo(),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                color: LivoColors.text,
                icon: const Icon(Icons.notifications_none, size: 24),
              ),
              IconButton(
                onPressed: onSearch,
                color: LivoColors.text,
                icon: const Icon(Icons.search, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling category chips.
class CatChips extends StatelessWidget {
  const CatChips({super.key, required this.active, required this.onPick});

  final String active;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
        itemCount: livoCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = livoCategories[i];
          final on = c == active;
          return InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () => onPick(c),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: on ? LivoColors.text : LivoColors.surface,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                c,
                style: TextStyle(
                  color: on ? Colors.black : LivoColors.sub,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Section title with a trailing chevron ("실시간 인기 LIVE >").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LivoColors.text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Icon(Icons.chevron_right, size: 22, color: LivoColors.faint),
        ],
      ),
    );
  }
}
