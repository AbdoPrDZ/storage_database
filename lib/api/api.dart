import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage_database.dart';

export './request.dart';
export './response.dart';

class StorageAPI {
  final String apiUrl;
  final Map<String, String> Function(String url)? getHeaders;
  final bool log;

  const StorageAPI({
    required this.apiUrl,
    this.getHeaders,
    this.log = false,
  });

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
  }) =>
      request<T>(
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
  }) =>
      request<T>(
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
  }) =>
      request<T>(
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
  }) =>
      request<T>(
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
  }) =>
      request<T>(
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
