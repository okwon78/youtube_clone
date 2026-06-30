import 'package:flutter/material.dart';

import '../../models/broadcast.dart';
import '../../theme/livo_theme.dart';
import '../../widgets/broadcast_cards.dart';
import '../../widgets/livo_common.dart';

typedef OpenBroadcast = void Function(Broadcast data);

/// Home tab — category chips, a featured hero, then the "지금 뜨는 방송" list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpen, this.onSearch});

  final OpenBroadcast onOpen;
  final VoidCallback? onSearch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _cat = '전체';

  @override
  Widget build(BuildContext context) {
    final list = _cat == '전체'
        ? livoBroadcasts
        : livoBroadcasts.where((b) => b.cat == _cat).toList();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        LivoAppHeader(onSearch: widget.onSearch),
        CatChips(active: _cat, onPick: (c) => setState(() => _cat = c)),
        const SectionHeader('실시간 인기 LIVE'),
        FeaturedCard(
          data: livoFeatured,
          onOpen: () => widget.onOpen(livoFeatured),
        ),
        const SectionHeader('지금 뜨는 방송'),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text(
                '해당 카테고리 방송이 없어요',
                style: TextStyle(color: LivoColors.faint),
              ),
            ),
          )
        else
          for (var i = 0; i < list.length; i++) ...[
            BroadcastCard(data: list[i], onOpen: () => widget.onOpen(list[i])),
            if (i < list.length - 1)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: LivoColors.line,
                indent: 18,
                endIndent: 18,
              ),
          ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Explore tab — a two-column grid of broadcasts.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.onOpen, this.onSearch});

  final OpenBroadcast onOpen;
  final VoidCallback? onSearch;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _cat = '전체';

  @override
  Widget build(BuildContext context) {
    final filtered = _cat == '전체'
        ? livoBroadcasts
        : livoBroadcasts.where((b) => b.cat == _cat).toList();
    // Pad out to a full grid like the mockup.
    final grid = <Broadcast>[...filtered, ...livoBroadcasts].take(8).toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: LivoAppHeader(onSearch: widget.onSearch)),
        SliverToBoxAdapter(
          child: CatChips(
            active: _cat,
            onPick: (c) => setState(() => _cat = c),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  GridCard(data: grid[i], onOpen: () => widget.onOpen(grid[i])),
              childCount: grid.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ranking tab — broadcasts ordered by viewer count.
class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key, this.onSearch});

  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final ranked = <Broadcast>[...livoBroadcasts, livoFeatured]
      ..sort((a, b) => b.viewers.compareTo(a.viewers));
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        LivoAppHeader(onSearch: onSearch),
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 2, 18, 12),
          child: Text(
            '실시간 랭킹',
            style: TextStyle(
              color: LivoColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
        ),
        for (var i = 0; i < ranked.length; i++)
          _RankingRow(rank: i + 1, data: ranked[i]),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.rank, required this.data});

  final int rank;
  final Broadcast data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rank <= 3 ? LivoColors.accent : LivoColors.faint,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 54,
              height: 54,
              child: LivoImage(thumbUrl(data.seed, w: 120, h: 120)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.streamer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LivoColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: LivoColors.sub, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ViewPill(viewers: data.viewers),
        ],
      ),
    );
  }
}
