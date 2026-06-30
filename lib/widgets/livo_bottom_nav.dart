import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/livo_theme.dart';
import 'livo_common.dart';

/// A single tab definition for the bottom navigation.
class _NavItem {
  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _navItems = <_NavItem>[
  _NavItem('홈', Icons.home_outlined, Icons.home),
  _NavItem('탐색', Icons.explore_outlined, Icons.explore),
  _NavItem('랭킹', Icons.emoji_events_outlined, Icons.emoji_events),
  _NavItem('MY', Icons.person_outline, Icons.person),
];

/// Custom translucent bottom navigation matching the LIVO mockup. The MY tab
/// shows the user's avatar (ringed when active) once they're signed in.
class LivoBottomNav extends StatelessWidget {
  const LivoBottomNav({
    super.key,
    required this.active,
    required this.onSelect,
    this.avatarUrl,
  });

  final int active;
  final ValueChanged<int> onSelect;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xEB0C0C0F),
            border: Border(top: BorderSide(color: LivoColors.line)),
          ),
          padding: EdgeInsets.only(top: 8, bottom: bottomInset + 10),
          child: Row(
            children: [
              for (var i = 0; i < _navItems.length; i++)
                Expanded(
                  child: _NavButton(
                    item: _navItems[i],
                    active: active == i,
                    avatarUrl: i == _navItems.length - 1 ? avatarUrl : null,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
    this.avatarUrl,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? LivoColors.accent : LivoColors.faint;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatarUrl != null)
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? LivoColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipOval(child: LivoImage(avatarUrl!)),
              )
            else
              Icon(
                active ? item.activeIcon : item.icon,
                size: 24,
                color: color,
              ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: active ? LivoColors.text : LivoColors.faint,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
