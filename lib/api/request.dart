import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage_database.dart';

class APIRequest<T> {
  final String url;
  final RequestType type;
  final Map<String, String> headers;
  final Map<String, dynamic>? data;
  final List<http.MultipartFile> files;
  final Function(int bytes, int totalBytes)? onFilesUpload;
  final bool log;
  final String errorsField;
  final Map<String, String> Function(Map errors)? decodeErrors;
  final Encoding? encoding;

  const APIRequest(
    this.url, {
    this.type = RequestType.get,
    this.headers = const {},
    this.data,
    this.files = const [],
    this.onFilesUpload,
    this.log = false,
    this.errorsField = 'errors',
    this.decodeErrors,
    this.encoding,
  });

  Future<APIResponse<T>> send() async {
    if (log) {
      dev.log("[StorageDatabase.StorageAPI] reqUrl: $type - $url");
      dev.log("[StorageDatabase.StorageAPI] reqHeaders: $headers");
      dev.log("[StorageDatabase.StorageAPI] reqData: ${jsonEncode(data)}");
      dev.log("[StorageDatabase.StorageAPI] reqFiles: ${files.length} file");
    }

    String responseBody = '';
    Map<String, String> responseHeaders = {};

    int statusCode = 400;

    try {
      Uri uri = Uri.parse(url);

      if (files.isNotEmpty) {
        http.MultipartRequest request = MultipartRequest(
          '$type',
          Uri.parse(url),
          onFilesUpload,
        );
        request.files.addAll(files);
        request.fields.addAll({
          for (String key in (data ?? {}).keys) key: data![key].toString(),
        });
        request.headers.addAll(headers);

        http.StreamedResponse res = await request.send();
        statusCode = res.statusCode;
        responseBody = await res.stream.bytesToString();
        responseHeaders = res.headers;
      } else {
        http.Response response;

        if (type.isPost) {
          response = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else if (type.isPut) {
          response = await http.put(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else if (type.isPatch) {
          response = await http.patch(
            uri,
            headers: headers,
            body: jsonEncode(data),
            encoding: encoding,
          );
        } else if (type.isDelete) {
          response = await http.delete(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else {
          response = await http.get(uri, headers: headers);
        }

        responseBody = response.body;
        statusCode = response.statusCode;
        responseHeaders = response.headers;
      }

      return APIResponse.fromResponse<T>(
        responseBody,
        statusCode,
        log: log,
        errorsField: errorsField,
        decodeErrors: decodeErrors,
        headers: responseHeaders,
      );
    } on SocketException {
      if (log) {
        dev.log(
          "[StorageDatabase.StorageAPI] reqError: No Internet Connection",
        );
      }

      return APIResponse<T>(false, "No Internet Connection", 503);
    } catch (e) {
      return APIResponse<T>(false, 'ExceptionError: $e', statusCode);
    }
  }

  factory APIRequest.get(
    String url, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    String errorsField = 'errors',
  }) => APIRequest(
    url,
    type: RequestType.get,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
  );

  factory APIRequest.post(
    String url, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    String errorsField = 'errors',
  }) => APIRequest(
    url,
    type: RequestType.post,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
  );

  factory APIRequest.put(
    String url, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    String errorsField = 'errors',
  }) => APIRequest(
    url,
    type: RequestType.put,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
  );

  factory APIRequest.patch(
    String url, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    String errorsField = 'errors',
  }) => APIRequest(
    url,
    type: RequestType.patch,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
  );

  factory APIRequest.delete(
    String url, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    String errorsField = 'errors',
  }) => APIRequest(
    url,
    type: RequestType.delete,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
  );
}

enum RequestType {
  get,
  post,
  put,
  patch,
  delete;

  @override
  String toString() => all[this]!;

  bool get isGet => this == get;
  bool get isPost => this == post;
  bool get isPut => this == put;
  bool get isPatch => this == patch;
  bool get isDelete => this == delete;

  static Map<RequestType, String> all = {
    get: 'GET',
    post: 'POST',
    put: 'PUT',
    patch: 'PATCH',
    delete: 'DELETE',
  };
}

class MultipartRequest extends http.MultipartRequest {
  final Function(int bytes, int totalBytes)? onProgress;

  MultipartRequest(super.method, super.url, this.onProgress);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();

    if (onProgress == null) return byteStream;

    final total = contentLength;
    int bytes = 0;

    final t = StreamTransformer.fromHandlers(
      handleData: (List<int> data, EventSink<List<int>> sink) {
        bytes += data.length;

        if (onProgress != null) onProgress!(bytes, total);

        if (total >= bytes) sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(t));
  }
}
