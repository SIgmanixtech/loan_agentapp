import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/appTheme.dart';
import 'screens/auth/login.dart';
import 'screens/auth/signup.dart';
import 'screens/auth/splash.dart';
import 'screens/agent/agentShell.dart';
import 'services/authSession.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  runApp(const AgentApp());
}

class AgentApp extends StatelessWidget {
  const AgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Loan Agent',

      theme: AppTheme.lightTheme,

      navigatorKey: AuthSession.navigatorKey,

      scaffoldMessengerKey: AuthSession.messengerKey,

      initialRoute: '/splash',

      routes: {
        '/splash': (context) => const AgentSplash(),
        '/login': (context) => const AgentLogin(),
        '/signup': (context) => const AgentSignup(),
        '/agent': (context) => const AgentShell(),
      },
    );
  }
}
