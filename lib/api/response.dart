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

  const APIResponse(
    this.success,
    this.message,
    this.statusCode, {
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

      final value = values.length == 1
          ? values[values.keys.first]
          : values.isNotEmpty
          ? values
          : null;

      if (log) {
        dev.log(
          "[StorageDatabase.StorageAPI.Response] - reqErrors: ${jsonEncode(errors)}",
        );
        dev.log(
          "[StorageDatabase.StorageAPI.Response] - reqValue: ${jsonEncode(value)}",
        );
      }

      return APIResponse<T>(
        responseData["success"] ?? statusCode == 200,
        responseData["message"] ?? 'No response message',
        statusCode,
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

      return APIResponse(false, "body: $body...", statusCode, body: strBody);
    }
  }
}
