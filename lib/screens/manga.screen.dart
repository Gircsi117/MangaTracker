import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:manga_tracker/services/manga.service.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/types/manga.type.dart';
import 'package:manga_tracker/widgets/navbar.widget.dart';
import 'package:photo_view/photo_view.dart';

class MangaScreen extends StatefulWidget {
  final String slug;
  final MangaService service;

  const MangaScreen({super.key, required this.slug, required this.service});

  @override
  State<MangaScreen> createState() => _MangaDetailsScreenState();
}

class _MangaDetailsScreenState extends State<MangaScreen> {
  Manga? _manga;
  List<Chapter> _chapters = [];
  bool _isReversed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = widget.service.create(widget.slug);
    final manga = await service.getMangaDetails();
    final chapters = await service.getChapterList();

    if (!mounted) return;
    setState(() {
      _manga = manga;
      _chapters = chapters;
      _isLoading = false;
    });
  }

  void _showCoverFullscreen() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(
                  _manga?.coverUrl ?? "",
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Chapter> get _sortedChapters =>
      _isReversed ? _chapters.reversed.toList() : _chapters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: Navbar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_manga == null) {
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
                'Az oldal nem elérhető, vagy a tartalom nem található!',
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

    return _buildContent();
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Blur háttér
        _buildBlurBackground(),
        // Tartalom
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                _buildMangaInfo(),
                _buildDescription(),
                _buildChapterList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 300,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: _manga?.coverUrl ?? "",
            httpHeaders: widget.service.headers,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            memCacheWidth: 300,
            color: Colors.black.withValues(alpha: 0.5),
            colorBlendMode: BlendMode.darken,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        onPressed: () => Navigator.pushNamed(
          context,
          '/manga_list',
          arguments: widget.service,
        ),
        icon: const Icon(Icons.arrow_back, color: AppColors.fontMuted),
      ),
    );
  }

  Widget _buildMangaInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _showCoverFullscreen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _manga?.coverUrl ?? "",
                httpHeaders: widget.service.headers,
                width: 120,
                height: 180,
                memCacheWidth: 240,
                memCacheHeight: 360,
                fit: BoxFit.fill,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => const SizedBox(
                  width: 120,
                  height: 180,
                  child: Center(
                    child: Icon(
                      Icons.menu_book_outlined,
                      size: 32,
                      color: AppColors.imagePlaceholder,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  width: 120,
                  height: 180,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 32,
                      color: AppColors.imagePlaceholder,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _manga?.title ?? "",
                  style: const TextStyle(
                    color: AppColors.font,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetail(Icons.person, _manga?.author ?? "Unknown"),
                _buildDetail(Icons.book, _manga?.type ?? "Unknown"),
                _buildDetail(Icons.source, widget.service.name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.fontMuted),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppColors.fontMuted)),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        _manga?.description ?? "",
        style: const TextStyle(color: Color(0xFFCCCCCC), height: 1.5),
      ),
    );
  }

  Widget _buildChapterList() {
    if (_chapters.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${_chapters.length} fejezet',
                style: const TextStyle(
                  color: AppColors.fontMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _isReversed = !_isReversed),
                icon: const Icon(Icons.swap_vert, color: AppColors.fontMuted),
              ),
            ],
          ),
          ..._sortedChapters.map((chapter) => _buildChapterItem(chapter)),
        ],
      ),
    );
  }

  Widget _buildChapterItem(Chapter chapter) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/chapter',
        arguments: {
          'slug': _manga?.slug ?? "",
          'chapterSlug': chapter.slug,
          'service': widget.service,
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${chapter.number}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                chapter.title,
                style: const TextStyle(color: AppColors.font, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chapter.publishedAt.isNotEmpty)
              Text(
                chapter.publishedAt,
                style: const TextStyle(
                  color: AppColors.fontMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
