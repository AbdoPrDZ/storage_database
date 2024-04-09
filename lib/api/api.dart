import 'package:http/http.dart' as http;

import '../storage_database.dart';

export './request.dart';
export './response.dart';

class StorageAPI {
  final String apiUrl;

  StorageAPI({
    required this.apiUrl,
    Map<String, String> headers = const {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json'
    },
  });

  Future<APIResponse<T>> request<T>(
    String target,
    RequestType type, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) =>
      APIRequest(apiUrl, headers).send(
        target,
        type,
        data: data,
        files: files,
        onFilesUpload: onFilesUpload,
        log: log,
        headers: headers,
        appendHeader: appendHeader,
        errorsField: errorsField,
      );
}
