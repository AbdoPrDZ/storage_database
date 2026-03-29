import 'dart:convert';
import 'dart:developer' as dev;

class APIResponse<T> {
  final bool success;
  final String message;
  final int statusCode;
  final Map<String, String>? errors;
  final T? value;
  final dynamic body;
  final Map<String, String> headers;

  const APIResponse({
    required this.success,
    required this.message,
    required this.statusCode,
    this.errors,
    this.body,
    this.value,
    this.headers = const {},
  });

  static APIResponse<T> fromResponse<T>(
    String response,
    int statusCode, {
    bool log = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
    Map<String, String> headers = const {},
    T Function(dynamic value)? parseResponse,
  }) {
    try {
      Map responseData = jsonDecode(response);

      if (!responseData.containsKey('message')) {
        switch (statusCode) {
          case 200:
            responseData["message"] = "No response message";
            break;
          case 400:
            responseData["message"] = "Error[$statusCode]: Bad request";
            break;
          case 403:
            responseData["message"] =
                "Error[$statusCode]: Unauthorized response";
            break;
          default:
            responseData["message"] =
                "response failed with status: $statusCode";
        }
      }

      Map values = {
        for (var key in responseData.keys)
          if (!["success", "message", errorsField].contains(key))
            key: responseData[key],
      };

      Map<String, String> errors = responseData.containsKey(errorsField)
          ? decodeErrors?.call(responseData[errorsField]) ??
                Map<String, String>.from(responseData[errorsField]!)
          : {};

      dynamic rawValue = values.length == 1
          ? values[values.keys.first]
          : values.isNotEmpty
          ? values
          : null;

      T? value;

      if (parseResponse != null && rawValue != null) {
        value = parseResponse(rawValue);
      } else {
        value = rawValue as T?;
      }

      if (log) {
        dev.log(
          "[StorageDatabase.StorageAPI.Response] - reqErrors: ${jsonEncode(errors)}",
        );
        dev.log(
          "[StorageDatabase.StorageAPI.Response] - reqValue: ${jsonEncode(value)}",
        );
      }

      return APIResponse<T>(
        success: responseData["success"] ?? statusCode == 200,
        message: responseData["message"] ?? 'No response message',
        statusCode: statusCode,
        errors: errors,
        body: responseData,
        value: value as T,
        headers: headers,
      );
    } catch (e) {
      String strBody = response.toString();
      String body = strBody.substring(
        0,
        strBody.length < 50 ? strBody.length : 50,
      );

      if (log) {
        dev.log("[StorageDatabase.StorageAPI.Response] - reqErr: $e");
        dev.log("[StorageDatabase.StorageAPI.Response] - resBody: $body");
      }

      return APIResponse(
        success: false,
        message: "body: $body...",
        statusCode: statusCode,
        body: strBody,
      );
    }
  }

  APIResponse<T> copyWith<T>({
    bool? success,
    String? message,
    int? statusCode,
    Map<String, String>? errors,
    T? value,
    dynamic body,
    Map<String, String>? headers,
  }) => APIResponse<T>(
    success: success ?? this.success,
    message: message ?? this.message,
    statusCode: statusCode ?? this.statusCode,
    errors: errors ?? this.errors,
    value: value ?? this.value as T?,
    body: body ?? this.body,
    headers: headers ?? this.headers,
  );
}
