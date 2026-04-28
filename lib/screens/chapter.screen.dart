import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:manga_tracker/services/manga.service.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/types/manga.type.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ChapterScreen extends StatefulWidget {
  final String slug;
  final ChapterSlug chapterSlug;
  final MangaService service;

  const ChapterScreen({
    super.key,
    required this.slug,
    required this.chapterSlug,
    required this.service,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  ChapterContent? _content;
  bool _showControls = false;
  int _currentPage = 0;

  late MangaService _pageService;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _pageService = widget.service.create(widget.slug);
    _loadPages();
    _hideSystemUI();
    _itemPositionsListener.itemPositions.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _showSystemUI();
    _itemPositionsListener.itemPositions.removeListener(_updateProgress);
    super.dispose();
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _updateProgress() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final sorted = positions.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    setState(() => _currentPage = sorted.first.index + 1);
  }

  Future<void> _loadPages() async {
    setState(() => _content = null);
    final content = await _pageService.getPageList(widget.chapterSlug);
    if (!mounted) return;

    final processedPages = await _processPages(content.pages);
    setState(() => _content = content.copyWith(pages: processedPages));
  }

  Future<List<ChapterPage>> _processPages(List<ChapterPage> pages) async {
    final result = <ChapterPage>[];

    for (final page in pages) {
      final response = await http.get(
        Uri.parse(page.imageUrl),
        headers: widget.service.headers,
      );

      final original = img.decodeImage(response.bodyBytes);
      if (original == null) continue;

      // Ha a kép magassága nagyobb mint 3000px, felszeleteljük
      if (original.height > 3000) {
        const sliceHeight = 1200;
        int y = 0;
        int sliceIndex = 0;

        while (y < original.height) {
          final height = (y + sliceHeight > original.height)
              ? original.height - y
              : sliceHeight;

          final slice = img.copyCrop(
            original,
            x: 0,
            y: y,
            width: original.width,
            height: height,
          );

          result.add(
            ChapterPage(
              id: "${page.id}_$sliceIndex",
              index: result.length,
              imageUrl: page.imageUrl,
              imageBytes: Uint8List.fromList(img.encodeJpg(slice, quality: 90)),
            ),
          );

          y += sliceHeight;
          sliceIndex++;
        }
      } else {
        result.add(page);
      }
    }

    return result;
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _navigateToChapter(ChapterSlug chapterSlug) {
    _itemScrollController.jumpTo(index: 0);
    Navigator.pushReplacementNamed(
      context,
      '/chapter',
      arguments: {
        'slug': widget.slug,
        'chapterSlug': chapterSlug,
        'service': widget.service,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _content == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _buildReader(),
    );
  }

  Widget _buildReader() {
    final pages = _content!.pages;

    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleControls,
          child: ScrollablePositionedList.builder(
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            itemCount: pages.length,
            itemBuilder: (context, index) => _buildPageImage(pages[index]),
          ),
        ),

        if (_showControls) ...[_buildTopBar(), _buildBottomBar()],

        _buildProgressBar(),
      ],
    );
  }

  Widget _buildProgressBar() {
    final total = _content?.pages.length ?? 0;
    final progress = total == 0 ? 0.0 : _currentPage / total;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "$_currentPage / $total",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPageImage(ChapterPage page) {
    if (page.imageBytes != null) {
      return Image.memory(
        page.imageBytes!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CachedNetworkImage(
          imageUrl: page.imageUrl,
          httpHeaders: widget.service.headers,
          width: constraints.maxWidth,
          fit: BoxFit.fitWidth,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxWidth * 1.5,
            child: Container(color: AppColors.imagePlaceholder),
          ),
          errorWidget: (context, url, error) => SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxWidth * 1.5,
            child: Container(color: AppColors.imagePlaceholder),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 12,
          right: 12,
        ),
        color: const Color(0xC0000000),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/manga',
                arguments: {'slug': widget.slug, 'service': widget.service},
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            Expanded(
              child: Text(
                _content?.currChapter?.title ?? "",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 38),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final prev = _content?.prevChapter;
    final next = _content?.nextChapter;

    if (prev == null && next == null) return const SizedBox();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          top: 12,
          left: 16,
          right: 16,
        ),
        color: const Color(0xC0000000),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (prev != null)
              GestureDetector(
                onTap: () => _navigateToChapter(prev.slug),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left, color: Colors.white, size: 16),
                      Text(
                        'Előző',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(),
            if (next != null)
              GestureDetector(
                onTap: () => _navigateToChapter(next.slug),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Következő',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }
}
