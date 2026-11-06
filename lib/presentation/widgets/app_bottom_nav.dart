import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_rounded),
          label: loc != null ? loc.appTitle : 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history_rounded),
          label: loc != null ? loc.historyTitle : 'Lịch sử nghe',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_rounded),
          label: loc != null ? loc.profilePageTitle : 'Cá nhân',
        ),
      ],
    );
  }
}
