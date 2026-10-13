import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/memo/presentation/memo_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: PersonalAssistantApp(),
    ),
  );
}

class PersonalAssistantApp extends ConsumerWidget {
  const PersonalAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeDataProvider);
    final auth = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Personal Assistant',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: auth.isAuthenticated
          ? const MemoListPage()
          : const LoginPage(),
    );
  }
}
