import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:manga_tracker/services/manga.service.dart';
import 'package:manga_tracker/styles/colors.style.dart';
import 'package:manga_tracker/types/manga.type.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;

class ReaderSettings {
  final bool sliceLargeImages;
  final int sliceThreshold;
  final int sliceHeight;
  final double pageSpacing;

  const ReaderSettings({
    this.sliceLargeImages = false,
    this.sliceThreshold = 3000,
    this.sliceHeight = 1200,
    this.pageSpacing = 0,
  });

  ReaderSettings copyWith({
    bool? sliceLargeImages,
    int? sliceThreshold,
    int? sliceHeight,
    double? pageSpacing,
  }) {
    return ReaderSettings(
      sliceLargeImages: sliceLargeImages ?? this.sliceLargeImages,
      sliceThreshold: sliceThreshold ?? this.sliceThreshold,
      sliceHeight: sliceHeight ?? this.sliceHeight,
      pageSpacing: pageSpacing ?? this.pageSpacing,
    );
  }
}

class ChapterScreen extends StatefulWidget {
  final String slug;
  final ChapterSlug chapterSlug;
  final MangaService service;
  final ReaderSettings? initialSettings;

  const ChapterScreen({
    super.key,
    required this.slug,
    required this.chapterSlug,
    required this.service,
    this.initialSettings,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  ChapterContent? _content;
  bool _showControls = false;
  bool _showSettings = false;
  int _currentPage = 0;
  late ReaderSettings _settings;

  late MangaService _pageService;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings ?? const ReaderSettings();
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
    if (!_settings.sliceLargeImages) return pages;

    final result = <ChapterPage>[];

    for (final page in pages) {
      final response = await http.get(
        Uri.parse(page.imageUrl),
        headers: widget.service.headers,
      );

      final original = img.decodeImage(response.bodyBytes);
      if (original == null) continue;

      if (original.height > _settings.sliceThreshold) {
        int y = 0;
        int sliceIndex = 0;

        while (y < original.height) {
          final height = (y + _settings.sliceHeight > original.height)
              ? original.height - y
              : _settings.sliceHeight;

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

          y += _settings.sliceHeight;
          sliceIndex++;
        }
      } else {
        result.add(page);
      }
    }

    return result;
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (!_showControls) _showSettings = false;
    });
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
        'initialSettings': _settings,
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
            itemBuilder: (context, index) => Column(
              children: [
                _buildPageImage(pages[index]),
                if (_settings.pageSpacing > 0)
                  SizedBox(height: _settings.pageSpacing),
              ],
            ),
          ),
        ),

        if (_showControls) ...[_buildTopBar(), _buildBottomBar()],

        if (_showSettings) _buildSettingsPanel(),

        _buildProgressBar(),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 260,
      child: GestureDetector(
        onTap: () {}, // ne zárja be ha rákattint
        child: Container(
          color: const Color(0xF0111111),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Olvasó beállítások',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Képtördelés toggle
              _buildSettingsToggle(
                label: 'Nagy képek tördelése',
                value: _settings.sliceLargeImages,
                onChanged: (val) => setState(
                  () => _settings = _settings.copyWith(sliceLargeImages: val),
                ),
              ),
              const SizedBox(height: 20),

              // Tördelési magasság
              if (_settings.sliceLargeImages) ...[
                _buildSettingsSlider(
                  label: 'Szelet magassága',
                  value: _settings.sliceHeight.toDouble(),
                  min: 600,
                  max: 2400,
                  divisions: 6,
                  displayValue: '${_settings.sliceHeight}px',
                  onChanged: (val) => setState(
                    () => _settings = _settings.copyWith(
                      sliceHeight: val.toInt(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Tördelési küszöb
                _buildSettingsSlider(
                  label: 'Tördelési küszöb',
                  value: _settings.sliceThreshold.toDouble(),
                  min: 1000,
                  max: 6000,
                  divisions: 10,
                  displayValue: '${_settings.sliceThreshold}px',
                  onChanged: (val) => setState(
                    () => _settings = _settings.copyWith(
                      sliceThreshold: val.toInt(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadPages,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Újragenerálás'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],

              // Oldalak közötti távolság
              _buildSettingsSlider(
                label: 'Oldalak közötti távolság',
                value: _settings.pageSpacing,
                min: 0,
                max: 32,
                divisions: 8,
                displayValue: '${_settings.pageSpacing.toInt()}px',
                onChanged: (val) => setState(
                  () => _settings = _settings.copyWith(pageSpacing: val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildSettingsSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              displayValue,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white12,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
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
            padding: const EdgeInsets.only(right: 20, bottom: 2),
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
        final double height = constraints.maxWidth * 1.5;

        return CachedNetworkImage(
          imageUrl: page.imageUrl,
          httpHeaders: widget.service.headers,
          width: constraints.maxWidth,
          fit: BoxFit.fitWidth,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 40,
                  color: AppColors.font.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Betöltés...',
                  style: TextStyle(
                    color: AppColors.font.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          errorWidget: (context, url, error) => SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 36,
                  color: AppColors.font.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'A kép nem tölthető be',
                  style: TextStyle(
                    color: AppColors.font.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
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
            // Settings gomb
            GestureDetector(
              onTap: () => setState(() => _showSettings = !_showSettings),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.tune,
                  color: _showSettings ? AppColors.primary : Colors.white,
                ),
              ),
            ),
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
