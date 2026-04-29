import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:manga_tracker/registry/mangaservices.registry.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/widgets/navbar.widget.dart';

class MangaServicesScreen extends StatelessWidget {
  const MangaServicesScreen({super.key});

  String _displayOrigin(String origin) {
    return origin
        .replaceFirst('https://', '')
        .replaceFirst('http://', '')
        .replaceFirst('www.', '');
  }

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
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemCount: mangaServicesRegistry.length,
                itemBuilder: (context, index) {
                  final service = mangaServicesRegistry[index];
                  return InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/manga_list',
                      arguments: service,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: service.logoUrl,
                              httpHeaders: service.headers,
                              width: 40,
                              height: 40,
                              memCacheWidth: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 20,
                                    color: AppColors.fontMuted,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 40,
                                height: 40,
                                color: AppColors.imagePlaceholder,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 18,
                                  color: AppColors.fontMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.name,
                            style: const TextStyle(
                              color: AppColors.font,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (service.origin.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _displayOrigin(service.origin),
                              style: const TextStyle(
                                color: AppColors.fontMuted,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }
}
