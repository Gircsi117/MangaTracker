import 'package:flutter/material.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/widgets/navbar.widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column()),
      bottomNavigationBar: Navbar(),
    );
  }
}
