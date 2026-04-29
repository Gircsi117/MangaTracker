import 'package:flutter/material.dart';
import 'package:manga_tracker/registry/mangaservices.registry.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/widgets/credential_setter.widget.dart';

class CredentialsScreen extends StatelessWidget {
  const CredentialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = mangaServicesRegistry.where((s) => s.needLogin).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Bejelentkezési adatok',
          style: TextStyle(
            color: AppColors.font,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.font),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: services
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CredentialSetter(id: s.id, name: s.name),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
