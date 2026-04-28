import 'package:manga_tracker/services/manga_pages/asurascans.service.dart';
import 'package:manga_tracker/services/manga_pages/mangabuddy.service.dart';
import 'package:manga_tracker/services/manga_pages/mangadexen.service.dart';
import 'package:manga_tracker/services/manga_pages/mangadexhu.service.dart';
import 'package:manga_tracker/services/manga_pages/manhwamania.service.dart';
import 'package:manga_tracker/services/manga_pages/padlizsanfansub.service.dart';
import 'package:manga_tracker/services/manga_pages/toonverse.service.dart';
import 'package:manga_tracker/services/manga.service.dart';

final List<MangaService> mangaServicesRegistry = [
  ToonVerseService(),
  MangaDexHuService(),
  MangaDexEnService(),
  AsuraScansService(),
  MangaBuddyService(),
  ManhwaManiaService(),
  PadlizsanFanSubService(),
]..sort((a, b) => a.name.compareTo(b.name));
