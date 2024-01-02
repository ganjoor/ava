import 'package:ava/models/common/pagination_metadata.dart';

class PaginatedItemsResponseModel<T> {
  final List<T> items;
  PaginationMetadata? paginationMetadata;
  final String error;

  PaginatedItemsResponseModel(
      {this.items = const [], this.paginationMetadata, this.error = ''});
}
