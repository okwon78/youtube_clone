import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_controller.dart';
import 'services/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Restore any persisted session before the first frame so the app opens
  // directly on the home page when the user is already logged in.
  final storage = TokenStorage();
  final token = await storage.readToken();
  final username = await storage.readUsername();
  final initialState = AuthState(token: token, username: username);

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
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.red)),
      home: const AuthGate(),
    );
  }
}

/// Shows the login page when logged out and the home page once authenticated.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authControllerProvider.select((s) => s.isAuthenticated),
    );
    return isAuthenticated ? const HomePage() : const LoginPage();
  }
}
