import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;

import '../storage_database.dart';

class APIRequest {
  final StorageDatabase storageDatabase;
  final String apiUrl;
  final Map<String, String> headers;

  APIRequest(this.storageDatabase, this.apiUrl, this.headers);

  Future<APIResponse<T>> send<T>(
    String target,
    RequestType type, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) async {
    if (appendHeader) headers = {...headers, ...this.headers};
    String url = '$apiUrl/$target';
    if (log) {
      dev.log("[StorageDatabaseAPI] reqUrl: $url");
      dev.log("[StorageDatabaseAPI] reqHeaders: $headers");
    }
    String responseBody = '';
    int statusCode = 400;
    try {
      Uri uri = Uri.parse(url);
      if (files.isNotEmpty) {
        http.MultipartRequest request = MultipartRequest(
          type.type,
          Uri.parse(url),
          onProgress: onFilesUpload,
        );
        request.files.addAll(files);
        request.fields.addAll({
          for (String key in (data ?? {}).keys) key: data![key].toString(),
        });
        request.headers.addAll(headers);
        http.StreamedResponse res = await request.send();
        statusCode = res.statusCode;
        responseBody = await res.stream.bytesToString();
      } else {
        http.Response response;
        if (type == RequestType.post) {
          response = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else if (type == RequestType.put) {
          response = await http.put(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else if (type == RequestType.patch) {
          response = await http.patch(
            uri,
            headers: headers,
            body: jsonEncode(data),
          );
        } else if (type == RequestType.delete) {
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
      }
      return APIResponse.fromResponse(
        responseBody,
        statusCode,
        log: log,
        errorsField: errorsField,
      );
    } on SocketException {
      if (log) dev.log("[StorageDatabaseAPI] reqError: No Internet Connection");
      return APIResponse<T>(false, "No Internet Connection", statusCode);
    } catch (e) {
      return APIResponse<T>(false, 'ExceptionError: $e', statusCode);
    }
  }
}

class RequestType {
  final String type;
  const RequestType(this.type);

  static const RequestType get = RequestType('GET');
  static const RequestType post = RequestType('POST');
  static const RequestType put = RequestType('PUT');
  static const RequestType patch = RequestType('PATCH');
  static const RequestType delete = RequestType('DELETE');

  static Map<String, RequestType> values = {
    get.type: get,
    post.type: post,
    put.type: put,
    patch.type: patch,
    delete.type: delete,
  };

  static RequestType? fromString(String type) => values[type];
}

class MultipartRequest extends http.MultipartRequest {
  final void Function(int bytes, int totalBytes)? onProgress;

  MultipartRequest(
    String method,
    Uri url, {
    this.onProgress,
  }) : super(method, url);

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
        if (total >= bytes) {
          sink.add(data);
        }
      },
    );
    final stream = byteStream.transform(t);
    return http.ByteStream(stream);
  }
}
