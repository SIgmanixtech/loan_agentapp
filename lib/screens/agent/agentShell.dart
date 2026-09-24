import 'package:flutter/material.dart';

import '../../services/agentAuthService.dart';
import '../../core/widgets/bottomNavigation.dart';

import 'dashboard.dart';
import 'myLoans.dart';
import 'myArea.dart';
import 'profile.dart';

class AgentShell extends StatefulWidget {
  const AgentShell({super.key});

  @override
  State<AgentShell> createState() => _AgentShellState();
}

class _AgentShellState extends State<AgentShell> {
  int currentIndex = 0;

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await AgentAuthService.logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _buildCurrentPage() {
    switch (currentIndex) {
      case 0:
        return AgentDashboard(onLogout: _logout);

      case 1:
        return AgentMyLoans(onLogout: _logout);

      case 2:
        return AgentMyArea(onLogout: _logout);

      case 3:
        return AgentProfile(onLogout: _logout);

      default:
        return AgentDashboard(onLogout: _logout);
    }
  }

  void _onNavigationTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),

      bottomNavigationBar: AgentBottomNavigation(
        currentIndex: currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}
