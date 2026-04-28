import 'package:flutter/material.dart';
import 'package:manga_tracker/styles/colors.style.dart';

class NavbarItemData {
  final String route;
  final IconData icon;
  final String title;

  const NavbarItemData({
    required this.route,
    required this.icon,
    required this.title,
  });
}

const List<NavbarItemData> navbarItems = [
  NavbarItemData(route: '/library', icon: Icons.book, title: 'Library'),
  NavbarItemData(route: '/history', icon: Icons.history, title: 'History'),
  NavbarItemData(
    route: '/manga_services',
    icon: Icons.compass_calibration,
    title: 'Browsing',
  ),
  NavbarItemData(route: '/settings', icon: Icons.settings, title: 'Settings'),
];

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: AppColors.border),
        ColoredBox(
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: Row(
              children: navbarItems.asMap().entries.map((entry) {
                final item = entry.value;
                final isActive = item.route == currentRoute;

                return Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, item.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.fontMuted,
                            size: 24,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.fontMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
