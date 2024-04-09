import 'package:http/http.dart' as http;

import '../storage_database.dart';

export './request.dart';
export './response.dart';

class StorageAPI {
  final String apiUrl;
  final Map<String, String> Function(String url)? getHeaders;

  StorageAPI({
    required this.apiUrl,
    this.getHeaders,
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
  }) {
    final url = '$apiUrl/$target';
    return APIRequest<T>(
      url,
      type: type,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
    ).send();
  }

  Future<APIResponse<T>> get<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) {
    final url = '$apiUrl/$target';
    return APIRequest<T>.get(
      url,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
    ).send();
  }

  Future<APIResponse<T>> post<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) {
    final url = '$apiUrl/$target';
    return APIRequest<T>.post(
      url,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
    ).send();
  }

  Future<APIResponse<T>> put<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) {
    final url = '$apiUrl/$target';
    return APIRequest<T>.put(
      url,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
    ).send();
  }

  Future<APIResponse<T>> patch<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) {
    final url = '$apiUrl/$target';
    return APIRequest<T>.patch(
      url,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
    ).send();
  }

  Future<APIResponse<T>> delete<T>(
    String target, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    String errorsField = 'errors',
  }) {
    final url = '$apiUrl/$target';
    return APIRequest<T>.delete(
      url,
      data: data,
      files: files,
      onFilesUpload: onFilesUpload,
      log: log,
      headers: appendHeader
          ? {...(getHeaders?.call(url) ?? {}), ...headers}
          : headers,
      errorsField: errorsField,
    ).send();
  }
}
