import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:manga_tracker/services/credentials.service.dart';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class KecskeFanSubService extends MangaService {
  @override
  String get id => "kecskefansub";

  @override
  String get name => "KecskeFanSub";

  @override
  String get origin => "https://www.kecskefansub.com";

  @override
  String get referer => "https://www.kecskefansub.com/";

  @override
  String get logoUrl => "https://www.kecskefansub.com/images/menu/logo.png";

  @override
  bool get needLogin => true;

  @override
  String get mangaUrl => "$origin/series/$slug";

  KecskeFanSubService([super.slug = ""]);

  @override
  MangaService create(String slug) => KecskeFanSubService(slug);

  static final _cookieJar = CookieJar();
  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(BaseOptions(baseUrl: origin));
    dio.interceptors.add(CookieManager(_cookieJar));
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra["_retry"] != true) {
            error.requestOptions.extra["_retry"] = true;
            try {
              await _login();
              final retryResponse = await _dio.fetch(error.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
    return dio;
  }

  String _setUrl(String url) {
    if (url.startsWith("http")) return url;
    if (url.startsWith("/")) return "$origin$url";
    return "$origin/$url";
  }

  Future<void> _login() async {
    final credentials = CredentialsStore.instance.get(id);
    if (credentials == null) throw Exception("Missing credentials!");

    final loginDio = Dio(BaseOptions(baseUrl: origin));
    loginDio.interceptors.add(CookieManager(_cookieJar));

    await loginDio.post(
      "/index.php/api/login",
      data: FormData.fromMap({
        "username": credentials.login,
        "password": credentials.password,
        "remember_me": "1",
      }),
    );
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;
      final query = params.query ?? "";

      final res = await _dio.get("/");
      final document = html_parser.parse(res.data as String);

      final links = document.querySelectorAll(".card-link-wrapper");

      final mangas = links
          .map((link) {
            final href = link.attributes["href"] ?? "";
            final slug = href.split("/").where((s) => s.isNotEmpty).last;
            final img = link.querySelector(".card-main-image");
            final coverUrl = _setUrl(img?.attributes["src"] ?? "");
            final title = img?.attributes["alt"] ?? "Unknown";

            return Manga(
              id: slug.isNotEmpty ? slug : null,
              slug: slug,
              title: title,
              coverUrl: coverUrl,
              author: "",
              type: "",
              description: "",
            );
          })
          .where(
            (m) =>
                m.slug.isNotEmpty &&
                m.title.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      final paginated = mangas.skip(offset).take(limit).toList();
      return PaginatedList(items: paginated, totalCount: mangas.length);
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      if (manga != null) return manga;

      final res = await _dio.get("/series/$slug");
      final document = html_parser.parse(res.data as String);

      final dataDiv = document.querySelector(".main-content-frame");
      final img = dataDiv?.querySelector(".series-main-image");

      final coverUrl = _setUrl(img?.attributes["src"] ?? "");
      final title = img?.attributes["alt"] ?? "";

      final description =
          dataDiv
              ?.querySelector(".series-description-box")
              ?.querySelector("p")
              ?.text ??
          "";

      String type = "";
      for (final box in dataDiv?.querySelectorAll(".info-box") ?? []) {
        if (box.text.startsWith("Típus:")) {
          type = box.text.split(" ").last;
          break;
        }
      }

      manga = Manga(
        id: slug,
        slug: slug,
        title: title,
        coverUrl: coverUrl,
        author: "Unknown",
        type: type,
        description: description,
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

      final res = await _dio.get("/series/$slug");
      final document = html_parser.parse(res.data as String);

      final chapterItems = document
          .querySelectorAll(".series-chapter-item")
          .where((el) => !el.classes.contains("locked-item"))
          .toList();

      chapters = chapterItems.map((item) {
        final chapterSlug = item.attributes["data-chapter"] ?? "";
        final title =
            item.querySelector(".series-chapter-number")?.text.trim() ?? "";
        final number = double.tryParse(chapterSlug) ?? 0;
        final date =
            item.querySelector(".series-chapter-time")?.text.trim() ?? "";

        return Chapter(
          id: chapterSlug.isNotEmpty ? chapterSlug : null,
          slug: chapterSlug,
          number: number,
          title: title,
          publishedAt: date,
        );
      }).toList();

      return chapters;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug) async {
    try {
      final res = await _dio.get("/read/$slug/$chapterSlug");
      final document = html_parser.parse(res.data as String);

      final images = document.querySelectorAll(".reader-image");

      final pages = images.asMap().entries.map((entry) {
        final url = entry.value.attributes["src"] ?? "";
        return ChapterPage(index: entry.key, imageUrl: _setUrl(url));
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
