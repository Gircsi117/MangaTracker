import 'package:flutter/material.dart';
import 'package:manga_tracker/registry/mangaservices.registry.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/widgets/navbar.widget.dart';

class MangaServicesScreen extends StatelessWidget {
  const MangaServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Források',
                style: TextStyle(
                  color: AppColors.font,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: mangaServicesRegistry.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/manga_list',
                          arguments: service,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  service.logoUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  headers: service.headers,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: const TextStyle(
                                    color: AppColors.font,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.fontMuted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < mangaServicesRegistry.length - 1)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }
}