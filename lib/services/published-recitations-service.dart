import 'dart:convert';

import 'package:ava/models/common/paginated-items-response-model.dart';
import 'package:ava/models/common/pagination-metadata.dart';
import 'package:ava/models/recitation/PublicRecitationViewModel.dart';
import 'package:ava/services/gservice-address.dart';
import 'package:http/http.dart' as http;

class PublishedRecitationsService {
  Future<PaginatedItemsResponseModel<PublicRecitationViewModel>> getRecitations(
      int pageNumber, int pageSize, String searchTerm) async {
    try {
      var apiRoot = GServiceAddress.Url;
      http.Response response = await http.get(
          '$apiRoot/api/audio/published?PageNumber=$pageNumber&PageSize=$pageSize&searchTerm=$searchTerm',
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
          });

      if (response.statusCode == 200) {
        List<PublicRecitationViewModel> ret = [];
        List<dynamic> items = json.decode(response.body);
        for (var item in items) {
          ret.add(PublicRecitationViewModel.fromJson(item));
        }
        return PaginatedItemsResponseModel<PublicRecitationViewModel>(
            items: ret,
            paginationMetadata: PaginationMetadata.fromJson(
                json.decode(response.headers['paging-headers'])),
            error: '');
      } else {
        return PaginatedItemsResponseModel<PublicRecitationViewModel>(
            error: 'کد برگشتی: ' +
                response.statusCode.toString() +
                ' ' +
                response.body);
      }
    } catch (e) {
      return PaginatedItemsResponseModel<PublicRecitationViewModel>(
          error: 'سرور مشخص شده در تنظیمات در دسترس نیست.\u200Fجزئیات بیشتر: ' +
              e.toString());
    }
  }
}
