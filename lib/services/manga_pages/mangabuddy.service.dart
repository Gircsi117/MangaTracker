import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:uuid/uuid.dart';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class MangaBuddyService extends MangaService {
  @override
  String get id => "mangabuddy";

  @override
  String get name => "MangaBuddy";

  @override
  String get baseUrl => "https://mangabuddy.com";

  @override
  String get origin => "https://mangabuddy.com";

  @override
  String get referer => "https://mangabuddy.com/";

  @override
  String get logoUrl =>
      "https://mangabuddy.com/static/sites/mangabuddy/icons/android-chrome-192x192.png";

  @override
  String get mangaUrl => "$referer$slug";

  MangaBuddyService([super.slug = ""]);

  @override
  MangaService create(String slug) {
    return MangaBuddyService(slug);
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;
      final page = offset ~/ limit + 1;

      final uri = Uri.parse("$origin/search").replace(
        queryParameters: {
          "q": params.query ?? "",
          "status": "all",
          "page": page.toString(),
          "limit": limit.toString(),
          "offset": offset.toString(),
        },
      );

      final response = await http.get(uri, headers: headers);
      final document = parse(response.body);

      final items = document.querySelectorAll(".book-detailed-item");

      final paginationLinks =
          document.querySelector(".paginator")?.querySelectorAll("a") ?? [];
      final paginationCount =
          int.tryParse(
            paginationLinks.isNotEmpty ? paginationLinks.last.text.trim() : "1",
          ) ??
          1;

      final mangas = items.map((item) {
        final title = item.querySelector("a")?.attributes["title"] ?? "Unknown";
        final slug =
            item
                .querySelector("a")
                ?.attributes["href"]
                ?.replaceFirst("/", "") ??
            "";
        final coverUrl =
            item
                .querySelector(".thumb")
                ?.querySelector("a")
                ?.querySelector("img")
                ?.attributes["data-src"] ??
            "";
        final description =
            item.querySelector(".summary")?.querySelector("p")?.text.trim() ??
            "";

        return Manga(
          id: slug,
          slug: slug,
          title: title,
          coverUrl: coverUrl,
          author: "",
          description: description,
          type: "unknown",
        );
      }).toList();

      return PaginatedList(
        items: mangas,
        totalCount: mangas.length * paginationCount,
      );
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      if (manga != null) return manga;

      final response = await http.get(
        Uri.parse("$origin/$slug"),
        headers: headers,
      );

      final document = parse(response.body);
      final bookInfo = document.querySelector(".book-info");

      const uuid = Uuid();

      manga = Manga(
        id: uuid.v4(),
        slug: slug,
        title: bookInfo?.querySelector("h1")?.text.trim() ?? "Unknown",
        coverUrl:
            bookInfo?.querySelector("#cover img")?.attributes["data-src"] ?? "",
        description: document.querySelector(".content")?.text.trim() ?? "",
        author: "Unknown",
        type: "unknown",
      );

      return manga;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Chapter>> getChapterList() async {
    try {
      if (chapters.isNotEmpty) return chapters;

      final response = await http.get(
        Uri.parse("$origin/$slug"),
        headers: headers,
      );

      final document = parse(response.body);
      final items = document.querySelectorAll("#chapter-list li");

      chapters =
          items
              .map((li) {
                final slug =
                    li
                        .querySelector("a")
                        ?.attributes["href"]
                        ?.split("/")
                        .last ??
                    "";
                final id = li.attributes["id"] ?? "";
                final number =
                    double.tryParse(
                      id.split("-").length > 1 ? id.split("-")[1] : "0",
                    ) ??
                    0;

                return Chapter(
                  id: id,
                  slug: slug,
                  number: number,
                  title: li.querySelector(".chapter-title")?.text.trim() ?? "",
                  publishedAt: "",
                );
              })
              .where((c) => c.slug.isNotEmpty)
              .toList()
            ..sort((a, b) => b.number.compareTo(a.number));

      return chapters;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug) async {
    try {
      final response = await http.get(
        Uri.parse("$origin/$slug/$chapterSlug"),
        headers: headers,
      );

      final match = RegExp(
        r"var chapImages = '([^']+)'",
      ).firstMatch(response.body);

      if (match == null) {
        return ChapterContent(
          pages: [],
          currChapter: null,
          nextChapter: null,
          prevChapter: null,
        );
      }

      final urls = match.group(1)?.split(",") ?? [];

      final pages = urls.asMap().entries.map((entry) {
        return ChapterPage(
          id: entry.key.toString(),
          index: entry.key,
          imageUrl: entry.value.trim(),
        );
      }).toList();

      final curr = await getRelativeChapter(chapterSlug, 0);
      final next = await getRelativeChapter(chapterSlug, 1);
      final prev = await getRelativeChapter(chapterSlug, -1);

      return ChapterContent(
        pages: pages,
        currChapter: curr,
        nextChapter: next,
        prevChapter: prev,
      );
    } catch (e) {
      return ChapterContent(
        pages: [],
        currChapter: null,
        nextChapter: null,
        prevChapter: null,
      );
    }
  }
}
