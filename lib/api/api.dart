import 'dart:convert';

import 'package:http/http.dart' as http;

import '../src/storage_database_exception.dart';
import '../storage_database.dart';

export './request.dart';
export './response.dart';

class StorageAPI {
  final String apiUrl;
  final Map<String, String> Function(String url)? getHeaders;
  final bool log;

  const StorageAPI({required this.apiUrl, this.getHeaders, this.log = false});

  static StorageAPI? _instance;

  static bool get hasInstance => _instance != null;

  static StorageAPI get instance {
    if (!hasInstance) {
      throw const StorageDatabaseException(
        'StorageAPI instance has not initialized yet',
      );
    }

    return _instance!;
  }

  static initInstance({
    required String apiUrl,
    Map<String, String> Function(String url)? getHeaders,
    bool log = false,
    bool overide = false,
  }) {
    if (hasInstance && !overide) {
      throw const StorageDatabaseException(
        'StorageAPI instance has already initialized',
      );
    }

    _instance = StorageAPI(apiUrl: apiUrl, getHeaders: getHeaders, log: log);
  }

  Future<APIResponse<T>> request<T>(
    String target,
    RequestType type, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool? log,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Encoding? encoding,
  }) {
    final url = '$apiUrl/$target';

    return APIRequest<T>(
      url,
      type: type,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log ?? this.log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
      decodeErrors: decodeErrors,
      encoding: encoding,
    ).send();
  }

  Future<APIResponse<T>> get<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool? log,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Encoding? encoding,
  }) => request<T>(
    target,
    RequestType.get,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
    decodeErrors: decodeErrors,
    encoding: encoding,
  );

  Future<APIResponse<T>> post<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool? log,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Encoding? encoding,
  }) => request<T>(
    target,
    RequestType.post,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
    decodeErrors: decodeErrors,
    encoding: encoding,
  );

  Future<APIResponse<T>> put<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool? log,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Encoding? encoding,
  }) => request<T>(
    target,
    RequestType.put,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
    decodeErrors: decodeErrors,
    encoding: encoding,
  );

  Future<APIResponse<T>> patch<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool? log,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Encoding? encoding,
  }) => request<T>(
    target,
    RequestType.patch,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
    decodeErrors: decodeErrors,
    encoding: encoding,
  );

  Future<APIResponse<T>> delete<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool? log,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Encoding? encoding,
  }) => request<T>(
    target,
    RequestType.delete,
    data: data,
    files: files,
    onFilesUpload: onFilesUpload,
    log: log,
    headers: headers,
    errorsField: errorsField,
    decodeErrors: decodeErrors,
    encoding: encoding,
  );
}
