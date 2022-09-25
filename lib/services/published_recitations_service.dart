import 'dart:convert';

import 'package:ava/models/common/paginated_items_response_model.dart';
import 'package:ava/models/common/pagination_metadata.dart';
import 'package:ava/models/recitation/public_recitation_viewmodel.dart';
import 'package:ava/models/recitation/recitation_verse_sync.dart';
import 'package:ava/services/gservice_address.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';

class PublishedRecitationsService {
  Future<PaginatedItemsResponseModel<PublicRecitationViewModel>> getRecitations(
      int pageNumber, int pageSize, String searchTerm) async {
    try {
      var apiRoot = GServiceAddress.url;
      http.Response response = await http.get(
          Uri.parse(
              '$apiRoot/api/audio/published?PageNumber=$pageNumber&PageSize=$pageSize&searchTerm=$searchTerm'),
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
            error: 'کد برگشتی: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      return PaginatedItemsResponseModel<PublicRecitationViewModel>(
          error:
              'سرور مشخص شده در تنظیمات در دسترس نیست.\u200Fجزئیات بیشتر: $e');
    }
  }

  Future<Tuple2<PublicRecitationViewModel, String>> getRecitationById(
      int id) async {
    try {
      var apiRoot = GServiceAddress.url;
      http.Response response = await http
          .get(Uri.parse('$apiRoot/api/audio/published/$id'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      });

      if (response.statusCode == 200) {
        var ret =
            PublicRecitationViewModel.fromJson(json.decode(response.body));
        return Tuple2<PublicRecitationViewModel, String>(ret, '');
      } else {
        return Tuple2<PublicRecitationViewModel, String>(
            null, 'کد برگشتی: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      return Tuple2<PublicRecitationViewModel, String>(null,
          'سرور مشخص شده در تنظیمات در دسترس نیست.\u200Fجزئیات بیشتر: $e');
    }
  }

  Future<Tuple2<List<RecitationVerseSync>, String>> getVerses(int id) async {
    try {
      var apiRoot = GServiceAddress.url;
      http.Response response = await http.get(
          Uri.parse('$apiRoot/api/audio/verses/$id'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'});

      List<RecitationVerseSync> ret = [];
      if (response.statusCode == 200) {
        List<dynamic> items = json.decode(response.body);
        for (var item in items) {
          ret.add(RecitationVerseSync.fromJson(item));
        }
        return Tuple2<List<RecitationVerseSync>, String>(ret, '');
      } else {
        return Tuple2<List<RecitationVerseSync>, String>(
            null, 'کد برگشتی: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      return Tuple2<List<RecitationVerseSync>, String>(null,
          'سرور مشخص شده در تنظیمات در دسترس نیست.\u200Fجزئیات بیشتر: $e');
    }
  }
}
