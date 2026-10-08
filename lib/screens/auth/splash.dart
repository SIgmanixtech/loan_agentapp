import 'package:flutter/material.dart';

import '../../core/theme/appColors.dart';
import '../../services/authSession.dart';

class AgentSplash extends StatefulWidget {
  const AgentSplash({super.key});

  @override
  State<AgentSplash> createState() => _AgentSplashState();
}

class _AgentSplashState extends State<AgentSplash> {
  @override
  void initState() {
    super.initState();

    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final isLoggedIn = await AuthSession.instance.restoreSession();

    if (!mounted) {
      return;
    }

    if (isLoggedIn) {
      Navigator.pushNamedAndRemoveUntil(context, '/agent', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: AppColors.white,
                size: 36,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Loan Agent',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
