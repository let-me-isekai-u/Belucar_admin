
class PagedResponse<T> {
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final List<T> data;

  PagedResponse({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.data,
  });

  // Hàm chuyển đổi từ JSON sang Object
  // fromJsonT là một hàm callback để chuyển đổi từng item trong list data
  factory PagedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Object? json) fromJsonT,
      ) {
    return PagedResponse<T>(
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 20,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => fromJsonT(item))
          .toList(),
    );
  }
}