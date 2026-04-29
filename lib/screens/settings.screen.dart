import 'package:flutter/material.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/widgets/navbar.widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('Fiók'),
            _card([
              _row(
                context: context,
                icon: Icons.vpn_key,
                label: 'Bejelentkezési adatok',
                onTap: () => Navigator.pushNamed(context, '/credentials'),
              ),
              _divider(),
              _row(
                context: context,
                icon: Icons.folder_outlined,
                label: 'Kategóriák',
                onTap: () => Navigator.pushNamed(context, '/category'),
              ),
            ]),
            const SizedBox(height: 16),
            _sectionHeader('Adatok'),
            _card([
              _row(
                context: context,
                icon: Icons.download_outlined,
                label: 'Adatbázis exportálása',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Hamarosan elérhető!')),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.fontMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _row({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.fontMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.font, fontSize: 15),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.fontMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.border,
      indent: 48,
    );
  }
}
