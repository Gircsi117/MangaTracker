import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:manga_tracker/modules/date.module.dart';
import 'package:manga_tracker/services/credentials.service.dart';
import 'package:uuid/uuid.dart';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class PadlizsanFanSubService extends MangaService {
  @override
  String get id => "padlizsanfansub";

  @override
  String get name => "PadlizsanFanSub";

  @override
  String get baseUrl => "https://padlizsanfansub.hu/api";

  @override
  String get origin => "https://padlizsanfansub.hu";

  @override
  String get referer => "https://padlizsanfansub.hu/";

  @override
  String get logoUrl => "https://padlizsanfansub.hu/assets/logo.png";

  @override
  bool get needLogin => true;

  @override
  String get mangaUrl => "${referer}chapters.html?slug=$slug";

  PadlizsanFanSubService([super.slug = ""]);

  @override
  MangaService create(String slug) => PadlizsanFanSubService(slug);

  static final _cookieJar = CookieJar();
  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(BaseOptions(baseUrl: PadlizsanFanSubService().baseUrl));
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
    return "https://padlizsanfansub.hu$url";
  }

  Future<void> _login() async {
    final credentials = CredentialsStore.instance.get(id);
    if (credentials == null) throw Exception("Missing credentials!");

    final loginDio = Dio(
      BaseOptions(baseUrl: PadlizsanFanSubService().baseUrl),
    );
    loginDio.interceptors.add(CookieManager(_cookieJar));

    final res = await loginDio.post(
      "/auth/login",
      data: {
        "login": credentials.login,
        "password": credentials.password,
        "remember": true,
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    if (res.data["ok"] != true) {
      throw Exception(res.data["error"] ?? "Authentication failed");
    }
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;
      final query = params.query ?? "";

      final res = await _dio.get("/manga", queryParameters: {"search": query});

      const uuid = Uuid();
      final list = res.data as List;

      final mangas = list
          .map(
            (item) => Manga(
              id: uuid.v4(),
              slug: item["slug"] as String,
              title: item["title"] as String,
              coverUrl: _setUrl(item["cover_url"] as String),
              author: "",
              type: "",
              description: "",
            ),
          )
          .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
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

      final res = await _dio.get("/manga/$slug");
      final data = res.data;
      const uuid = Uuid();

      manga = Manga(
        id: uuid.v4(),
        slug: data["slug"] as String,
        title: data["title"] as String,
        coverUrl: _setUrl(data["cover_url"] as String),
        author: "Unknown",
        type: "Unknown",
        description: (data["description"] as String? ?? "").replaceAll(
          "<br>",
          "\n",
        ),
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

      final res = await _dio.get("/chapters/$slug");
      final data = (res.data["chapters"] as List)
          .where((item) => item["locked"] != true)
          .toList();

      const uuid = Uuid();

      chapters = data
          .asMap()
          .entries
          .map(
            (entry) => Chapter(
              id: uuid.v4(),
              slug: entry.value["folder"] as String,
              title: entry.value["title"] as String,
              number: (entry.key + 1).toDouble(),
              publishedAt: entry.value["scanned_at"] != null
                  ? DateModule.getDateString(
                      DateTime.parse(entry.value["scanned_at"] as String),
                    )
                  : "",
            ),
          )
          .toList()
          .reversed
          .toList();

      return chapters;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug) async {
    try {
      final res = await _dio.get("/pages/$slug/$chapterSlug");
      final data = res.data["pages"] as List;
      final folder = res.data["library"] as String;

      const uuid = Uuid();

      final pages = data.asMap().entries.map((entry) {
        return ChapterPage(
          id: uuid.v4(),
          index: entry.key,
          imageUrl:
              "$origin/api/image/$folder/$slug/$chapterSlug/${entry.value}",
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
      return ChapterContent.empty();
    }
  }
}
