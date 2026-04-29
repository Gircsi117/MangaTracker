import 'dart:typed_data';

import 'package:uuid/uuid.dart';

typedef ChapterSlug = dynamic;

class Manga {
  final String id;
  final String slug;
  final String title;
  final String coverUrl;
  final String author;
  final String description;
  final String type;

  Manga({
    String? id,
    required this.slug,
    required this.title,
    required this.coverUrl,
    required this.author,
    required this.description,
    required this.type,
  }) : id = id ?? const Uuid().v4();
}

class Chapter {
  final String id;
  final ChapterSlug slug;
  final double number;
  final String title;
  final String publishedAt;

  Chapter({
    String? id,
    required this.slug,
    required this.number,
    required this.title,
    required this.publishedAt,
  }) : id = id ?? const Uuid().v4();
}

class ChapterContent {
  final List<ChapterPage> pages;
  final Chapter? currChapter;
  final Chapter? nextChapter;
  final Chapter? prevChapter;

  const ChapterContent({
    required this.pages,
    this.currChapter,
    this.nextChapter,
    this.prevChapter,
  });

  ChapterContent.empty()
    : pages = [],
      currChapter = null,
      nextChapter = null,
      prevChapter = null;

  ChapterContent copyWith({
    List<ChapterPage>? pages,
    Chapter? currChapter,
    Chapter? nextChapter,
    Chapter? prevChapter,
  }) {
    return ChapterContent(
      pages: pages ?? this.pages,
      currChapter: currChapter ?? this.currChapter,
      nextChapter: nextChapter ?? this.nextChapter,
      prevChapter: prevChapter ?? this.prevChapter,
    );
  }
}

class ChapterPage {
  final String id;
  final int index;
  final String imageUrl;
  final Uint8List? imageBytes;

  ChapterPage({
    String? id,
    required this.index,
    required this.imageUrl,
    this.imageBytes,
  }) : id = id ?? const Uuid().v4();
}
