/// A single live broadcast shown across the home/explore/live/ranking screens.
///
/// This is placeholder content mirroring the design mockup. Thumbnails and
/// avatars resolve to `picsum.photos` seeds — swap for real stream thumbnails
/// when the backend exposes them.
class Broadcast {
  const Broadcast({
    required this.id,
    required this.title,
    required this.streamer,
    required this.cat,
    required this.viewers,
    required this.seed,
    required this.since,
    this.live = true,
  });

  final int id;
  final String title;
  final String streamer;
  final String cat;
  final int viewers;
  final String seed;
  final String since;
  final bool live;
}

/// Category chips shown above the broadcast lists.
const livoCategories = <String>['전체', '게임', '버추얼', '먹방', '토크', '음악', 'e스포츠'];

/// The hero broadcast pinned to the top of Home / first in the Live feed.
const livoFeatured = Broadcast(
  id: 0,
  title: 'MSI 2026 플레이-인 1라운드 생중계',
  streamer: 'LIVO e스포츠',
  cat: 'e스포츠',
  viewers: 103742,
  seed: 'livo-esports',
  since: '02:05:56',
);

/// The broadcast feed.
const livoBroadcasts = <Broadcast>[
  Broadcast(
    id: 1,
    title: '신메이플 같이 키우실 분 ❤ 뉴비 환영',
    streamer: '별빛초코',
    cat: '게임',
    viewers: 2367,
    seed: 'livo-game1',
    since: '03:35',
  ),
  Broadcast(
    id: 2,
    title: '오늘은 한우 먹방 갑니다 (24시간 노방종)',
    streamer: '먹깨비도롱',
    cat: '먹방',
    viewers: 5911,
    seed: 'livo-food1',
    since: '15:51',
  ),
  Broadcast(
    id: 3,
    title: '버추얼 신인 데뷔 87일차 ❤ 노래방 켰어요',
    streamer: '사주모리',
    cat: '버추얼',
    viewers: 1103,
    seed: 'livo-vt1',
    since: '01:12',
  ),
  Broadcast(
    id: 4,
    title: '[심야토크] 고민 들어주는 방송, 편하게 와요',
    streamer: '새벽라디오',
    cat: '토크',
    viewers: 1872,
    seed: 'livo-talk1',
    since: '02:12',
  ),
  Broadcast(
    id: 5,
    title: '랭크 마스터 가즈아 🔥 듀오 구함',
    streamer: '한빛GG',
    cat: '게임',
    viewers: 4280,
    seed: 'livo-game2',
    since: '04:08',
  ),
  Broadcast(
    id: 6,
    title: '어쿠스틱 라이브 🎸 신청곡 받습니다',
    streamer: '무지개음표',
    cat: '음악',
    viewers: 1420,
    seed: 'livo-music1',
    since: '01:06',
  ),
];

/// Formats a viewer count like the mockup: `103742 → 10.3만`, `2367 → 2,367`.
String fmtViewers(int n) {
  if (n >= 10000) {
    final v = (n / 10000).toStringAsFixed(1);
    return '${v.endsWith('.0') ? v.substring(0, v.length - 2) : v}만';
  }
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Placeholder thumbnail / avatar URLs (grayscale to read as "video still").
String thumbUrl(String seed, {int w = 400, int h = 240}) =>
    'https://picsum.photos/seed/$seed/$w/$h?grayscale';

String avatarUrl(String seed) => 'https://picsum.photos/seed/$seed-a/80/80';

/// Avatar for the signed-in user, derived deterministically from their name.
String meAvatarUrl(String? username) =>
    'https://picsum.photos/seed/livo-${username ?? 'me'}/120/120';
