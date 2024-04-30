import 'dart:convert';
import 'dart:developer' as dev;

class APIResponse<T> {
  final bool success;
  final String message;
  final int statusCode;
  final Map<String, String>? errors;
  final T? value;
  final dynamic body;

  const APIResponse(
    this.success,
    this.message,
    this.statusCode, {
    this.errors,
    this.body,
    this.value,
  });

  static APIResponse<T> fromResponse<T>(
    String response,
    int statusCode, {
    bool log = true,
    String errorsField = 'errors',
    Map<String, String> Function(Map errors)? decodeErrors,
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
            key: responseData[key]
      };

      final value = values.length == 1
          ? values[values.keys.first]
          : values.isNotEmpty
              ? values
              : null;

      return APIResponse<T>(
        responseData["success"] ?? false,
        responseData["message"] ?? 'No response message',
        statusCode,
        errors: responseData.containsKey(errorsField)
            ? decodeErrors?.call(responseData[errorsField]) ??
                Map<String, String>.from(responseData[errorsField]!)
            : {},
        body: responseData,
        value: value as T,
      );
    } catch (e) {
      String strBody = response.toString();
      String body = strBody.substring(
        0,
        strBody.length < 50 ? strBody.length : 50,
      );

      dev.log("[StorageDatabase.StorageAPI.Response] - ERROR: $e");
      dev.log("[StorageDatabase.StorageAPI.Response] - response-body: $body");

      return APIResponse(
        false,
        "body: $body...",
        statusCode,
        body: strBody,
      );
    }
  }
}
