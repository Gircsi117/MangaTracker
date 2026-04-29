// lib/screens/manga_list.screen.dart
import 'package:flutter/material.dart';
import 'package:manga_tracker/services/manga.service.dart';
import 'package:manga_tracker/hooks/search.state.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/types/manga.type.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:manga_tracker/widgets/navbar.widget.dart';

class MangaListScreen extends StatefulWidget {
  final MangaService service;

  const MangaListScreen({super.key, required this.service});

  @override
  State<MangaListScreen> createState() => _MangaListScreenState();
}

class _MangaListScreenState extends State<MangaListScreen> {
  late SearchState _searchState;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchState = SearchState(widget.service);
    _searchState.addListener(() => setState(() {}));
    _searchState.search();
  }

  @override
  void dispose() {
    _searchState.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Grid
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
      bottomNavigationBar: const Navbar(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, color: AppColors.font),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.font),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.service.logoUrl,
                      headers: widget.service.headers,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                hintText: 'Keresés...',
                hintStyle: const TextStyle(color: AppColors.fontMuted),
                filled: true,
                fillColor: AppColors.surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _searchState.handleSearch(value),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                _searchController.clear();
                _searchState.clearSearch();
              },
              icon: const Icon(Icons.close, color: AppColors.font),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_searchState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_searchState.mangas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.font.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'A keresett oldal nem elérhető, vagy a szűrők alapján nem található tartalom!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.font.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2 / 3,
            ),
            itemCount: _searchState.mangas.length,
            itemBuilder: (context, index) {
              final manga = _searchState.mangas[index];
              return _buildMangaItem(manga);
            },
          ),
        ),
        if (_searchState.totalPages > 1) _buildPagination(),
      ],
    );
  }

  Widget _buildMangaItem(Manga manga) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/manga',
        arguments: {'slug': manga.slug, 'service': widget.service},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CachedNetworkImage(
                  imageUrl: manga.coverUrl,
                  httpHeaders: widget.service.headers,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 300,
                  fadeInDuration: const Duration(milliseconds: 200),
                  placeholder: (context, url) => Container(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_outlined,
                        size: 32,
                        color: AppColors.font.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 28,
                          color: AppColors.font.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hiba',
                          style: TextStyle(
                            color: AppColors.font.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            manga.title,
            style: const TextStyle(color: AppColors.font, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Text(
            '${_searchState.page} / ${_searchState.totalPages} oldal',
            style: const TextStyle(color: AppColors.fontMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(_searchState.totalPages, (i) {
                final p = i + 1;
                final isActive = p == _searchState.page;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      _scrollToTop();
                      _searchState.handlePageChange(p);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$p',
                        style: TextStyle(
                          color: AppColors.font,
                          fontSize: 13,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
