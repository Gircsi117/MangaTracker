import 'package:cached_network_image/cached_network_image.dart';
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
                                child: CachedNetworkImage(
                                  imageUrl: service.logoUrl,
                                  httpHeaders: service.headers,
                                  width: 36,
                                  height: 36,
                                  memCacheWidth: 72,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: AppColors.fontMuted,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 36,
                                        height: 36,
                                        color: AppColors.imagePlaceholder,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          size: 16,
                                          color: AppColors.fontMuted,
                                        ),
                                      ),
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
