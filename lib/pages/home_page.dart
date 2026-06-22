import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_controller.dart';

/// A simple data model representing a single video in the feed.
class Video {
  const Video({
    required this.title,
    required this.channelName,
    required this.views,
    required this.uploadedAt,
    required this.duration,
  });

  final String title;
  final String channelName;
  final String views;
  final String uploadedAt;
  final String duration;
}

/// Placeholder feed data. This will be replaced with real data from the
/// backend resource server later in the tutorial.
const _demoVideos = <Video>[
  Video(
    title: 'Building a YouTube Clone in Flutter — Full Tutorial',
    channelName: 'Flutter Devs',
    views: '1.2M views',
    uploadedAt: '3 days ago',
    duration: '24:15',
  ),
  Video(
    title: 'OAuth2 Explained: Auth Server vs Resource Server',
    channelName: 'Backend Basics',
    views: '482K views',
    uploadedAt: '1 week ago',
    duration: '15:42',
  ),
  Video(
    title: 'Riverpod 3 State Management Crash Course',
    channelName: 'Code With Choi',
    views: '93K views',
    uploadedAt: '2 weeks ago',
    duration: '38:07',
  ),
  Video(
    title: 'Go + Gin + PostgreSQL REST API From Scratch',
    channelName: 'Backend Basics',
    views: '210K views',
    uploadedAt: '1 month ago',
    duration: '52:30',
  ),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.play_arrow, color: Colors.red, size: 28),
            const SizedBox(width: 4),
            Text(
              'YouTube',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        actions: [
          const IconButton(onPressed: null, icon: Icon(Icons.cast)),
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.notifications_outlined),
          ),
          const IconButton(onPressed: null, icon: Icon(Icons.search)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (context) {
              final username = ref.read(authControllerProvider).username;
              return [
                if (username != null)
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text('@$username'),
                  ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('로그아웃'),
                ),
              ];
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.builder(
        itemCount: _demoVideos.length,
        itemBuilder: (context, index) => _VideoCard(video: _demoVideos[index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Shorts',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.subscriptions_outlined),
            selectedIcon: Icon(Icons.subscriptions),
            label: 'Subs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail with duration badge.
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.duration,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
        // Channel avatar + title + metadata.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  video.channelName.characters.first,
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${video.channelName} · ${video.views} · ${video.uploadedAt}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, size: 20),
            ],
          ),
        ),
      ],
    );
  }
}
