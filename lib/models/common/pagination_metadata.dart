class PaginationMetadata {
  final int totalCount;
  final int pageSize;
  int currentPage;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;

  PaginationMetadata(
      {required this.totalCount,
      required this.pageSize,
      required this.currentPage,
      required this.totalPages,
      required this.hasPreviousPage,
      required this.hasNextPage});

  static PaginationMetadata? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return PaginationMetadata(
      totalCount: json['totalCount'],
      pageSize: json['pageSize'],
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
      hasPreviousPage: json['hasPreviousPage'],
      hasNextPage: json['hasNextPage'],
    );
  }
}
