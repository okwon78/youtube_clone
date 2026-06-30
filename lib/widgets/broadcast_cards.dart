import 'package:flutter/material.dart';

import '../models/broadcast.dart';
import '../theme/livo_theme.dart';
import 'livo_common.dart';

/// Large hero card pinned to the top of Home and used in the Live feed.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.data, required this.onOpen});

  final Broadcast data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: GestureDetector(
        onTap: onOpen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LivoImage(thumbUrl(data.seed, w: 720, h: 405)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1A000000), Color(0xA6000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      const LiveBadge(),
                      const SizedBox(width: 8),
                      _BlurChip(text: '👁 ${fmtViewers(data.viewers)}명 시청'),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.25,
                          shadows: [
                            Shadow(color: Color(0x80000000), blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.streamer} · ${data.cat}',
                        style: const TextStyle(
                          color: Color(0xD9FFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurChip extends StatelessWidget {
  const _BlurChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Horizontal list row: thumbnail + title + streamer + meta.
class BroadcastCard extends StatelessWidget {
  const BroadcastCard({super.key, required this.data, required this.onOpen});

  final Broadcast data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 148,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LivoImage(thumbUrl(data.seed)),
                      const Positioned(
                        top: 7,
                        left: 7,
                        child: LiveBadge(small: true),
                      ),
                      Positioned(
                        bottom: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xB3000000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data.since,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: LivoColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: LivoImage(avatarUrl(data.seed)),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          data.streamer,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LivoColors.sub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ViewPill(viewers: data.viewers),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: LivoColors.line),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.cat,
                          style: const TextStyle(
                            color: LivoColors.faint,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact two-column grid card used on the Explore screen.
class GridCard extends StatelessWidget {
  const GridCard({super.key, required this.data, required this.onOpen});

  final Broadcast data;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LivoImage(thumbUrl(data.seed)),
                  const Positioned(
                    top: 7,
                    left: 7,
                    child: LiveBadge(small: true),
                  ),
                  Positioned(
                    bottom: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xB3000000),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            fmtViewers(data.viewers),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LivoColors.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.streamer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: LivoColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
