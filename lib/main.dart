import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/livo/livo_shell.dart';
import 'providers/auth_controller.dart';
import 'services/token_storage.dart';
import 'theme/livo_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore any persisted session before the first frame so the app opens
  // directly on the home page when the user is already logged in.
  final storage = TokenStorage();
  final session = await storage.read();
  final initialState = AuthState(
    token: session?.accessToken,
    refreshToken: session?.refreshToken,
    username: session?.username,
  );

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        initialAuthStateProvider.overrideWithValue(initialState),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LIVO',
      theme: buildLivoTheme(),
      home: const LivoShell(),
    );
  }
}
