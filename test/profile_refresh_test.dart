import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livo/pages/livo/livo_shell.dart';
import 'package:livo/pages/livo/profile_page.dart';
import 'package:livo/providers/auth_controller.dart';
import 'package:livo/providers/profile_provider.dart';
import 'package:livo/services/livo_api.dart';

/// Counts how many times the livo server stats endpoint is hit, so the tests can
/// assert that a UI action actually re-calls it.
class _FakeLivoApi extends LivoApi {
  int calls = 0;

  @override
  Future<ProfileStats> fetchProfileStats(String accessToken) async {
    calls++;
    return (points: 8400, following: 24);
  }
}

void main() {
  Widget wrap(_FakeLivoApi fake, Widget child) {
    return ProviderScope(
      overrides: [
        livoApiProvider.overrideWithValue(fake),
        // Seed a signed-in session so the profile stats provider has a token.
        initialAuthStateProvider.overrideWithValue(
          const AuthState(token: 'test-token', username: 'tester'),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('pull-to-refresh re-calls the livo stats endpoint', (
    tester,
  ) async {
    final fake = _FakeLivoApi();
    await tester.pumpWidget(wrap(fake, const ProfileScreen()));
    await tester.pumpAndSettle();

    // Initial entry fetched once.
    expect(fake.calls, 1);

    // Pull down to trigger the RefreshIndicator.
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(fake.calls, 2, reason: 'pull-to-refresh should re-fetch');
  });

  testWidgets('re-entering the MY tab re-calls the livo stats endpoint', (
    tester,
  ) async {
    final fake = _FakeLivoApi();
    await tester.pumpWidget(wrap(fake, const LivoShell()));
    await tester.pumpAndSettle();

    // ProfileScreen lives in the IndexedStack from the start (offstage), so it
    // fetches once on mount.
    expect(fake.calls, 1);

    // Go to another tab, then back to MY — the shell should invalidate.
    await tester.tap(find.text('탐색'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MY'));
    await tester.pumpAndSettle();

    expect(fake.calls, 2, reason: 'MY-tab re-entry should re-fetch');
  });
}
