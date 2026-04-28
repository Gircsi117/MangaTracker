import 'package:flutter/material.dart';
import 'package:manga_tracker/services/manga.service.dart';
import 'package:manga_tracker/types/list.type.dart';
import 'package:manga_tracker/types/manga.type.dart';

const int _defaultLimit = 20;

class SearchState extends ChangeNotifier {
  final MangaService service;

  int page = 1;
  int totalCount = 0;
  int limit = _defaultLimit;
  bool isLoading = false;
  List<Manga> mangas = [];
  String _currentQuery = "";

  SearchState(this.service);

  int get totalPages => totalCount == 0 ? 0 : (totalCount / limit).ceil();

  Future<void> search({
    int? currentPage,
    int? currentLimit,
    String? currentQuery,
  }) async {
    final p = currentPage ?? 1;
    final l = currentLimit ?? _defaultLimit;
    final q = currentQuery ?? "";

    isLoading = true;
    mangas = [];
    notifyListeners();

    try {
      final result = await service.getMangaList(ListParams(
        query: q.trim(),
        limit: l,
        offset: (p - 1) * l,
      ));

      mangas = result.items;
      totalCount = result.totalCount;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      mangas = [];
      totalCount = 0;
      notifyListeners();
    }
  }

  void handleSearch(String query) {
    _currentQuery = query;
    page = 1;
    limit = _defaultLimit;
    search(currentPage: 1, currentLimit: _defaultLimit, currentQuery: query);
  }

  void handlePageChange(int newPage) {
    page = newPage;
    search(currentPage: newPage, currentLimit: limit, currentQuery: _currentQuery);
  }

  void clearSearch() {
    _currentQuery = "";
    page = 1;
    limit = _defaultLimit;
    mangas = [];
    totalCount = 0;
    notifyListeners();
    search(currentPage: 1, currentLimit: _defaultLimit, currentQuery: "");
  }
}