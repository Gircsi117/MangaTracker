import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:manga_tracker/db/db.dart";
import "package:manga_tracker/services/credentials.service.dart";
import "package:manga_tracker/modules/date.module.dart";
import "package:manga_tracker/screens/chapter.screen.dart";
import "package:manga_tracker/screens/manga.screen.dart";
import "package:manga_tracker/screens/mangalist.screen.dart";
import "package:manga_tracker/services/manga.service.dart";
import "package:manga_tracker/styles/colors.style.dart";
import "package:provider/provider.dart";
import "screens/mangaservices.screen.dart";
import "./screens/library.screen.dart";
import "./screens/history.screen.dart";
import "./screens/settings.screen.dart";
import "./screens/credentials.screen.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.init();
  await DateModule.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await CredentialsStore.instance.load();

  runApp(
    ChangeNotifierProvider.value(
      value: CredentialsStore.instance,
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // styles
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: AppColors.surface,
            elevation: 0,
          ),
        ),
        // routes
        initialRoute: "/library",
        onGenerateRoute: (settings) {
          Widget screen;

          switch (settings.name) {
            case '/manga_list':
              final service = settings.arguments as MangaService;
              screen = MangaListScreen(service: service);
              break;
            case '/manga':
              final args = settings.arguments as Map<String, dynamic>;
              screen = MangaScreen(
                slug: args['slug'],
                service: args['service'] as MangaService,
              );
              break;
            case '/chapter':
              final args = settings.arguments as Map<String, dynamic>;
              screen = ChapterScreen(
                slug: args['slug'],
                chapterSlug: args['chapterSlug'],
                service: args['service'] as MangaService,
                initialSettings: args['initialSettings'] as ReaderSettings?,
              );
              break;
            default:
              final routes = {
                '/': const LibraryScreen(),
                '/library': const LibraryScreen(),
                '/history': const HistoryScreen(),
                '/manga_services': const MangaServicesScreen(),
                '/settings': const SettingsScreen(),
                '/credentials': const CredentialsScreen(),
              };
              screen = routes[settings.name] ?? const LibraryScreen();
          }

          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => screen,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        },
      ),
    );
  }
}
