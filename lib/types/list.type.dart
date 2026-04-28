class PaginatedList<T> {
  final List<T> items;
  final int totalCount;

  const PaginatedList({required this.items, required this.totalCount});
}

class ListParams {
  final int? limit;
  final int? offset;
  final String? order; // 'asc' vagy 'desc'
  final String? query;

  const ListParams({this.limit, this.offset, this.order, this.query});
}