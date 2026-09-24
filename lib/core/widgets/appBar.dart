import 'package:flutter/material.dart';

import '../theme/appColors.dart';

class AgentAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onLogout;

  const AgentAppBar({
    super.key,
    required this.title,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      backgroundColor: AppColors.white,

      foregroundColor: AppColors.black,

      elevation: 0,

      centerTitle: false,

      actions: [
        if (onLogout != null)
          IconButton(
            tooltip: 'Logout',
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout,
            ),
          ),

        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(
        kToolbarHeight,
      );
}