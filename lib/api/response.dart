import 'dart:convert';

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
  }) {
    if (log) print("response body: $response");
    try {
      Map responseData = jsonDecode(response);
      if (statusCode == 200) {
        if (responseData.containsKey(errorsField)) {
          Map<String, String> errors = {};
          for (String name in (responseData[errorsField] as Map).keys) {
            try {
              errors[name] =
                  (responseData[errorsField][name] as List).join(', ');
            } catch (e) {
              errors[name] = responseData[errorsField][name].toString();
            }
          }
          responseData[errorsField] = errors;
        }
      } else {
        switch (statusCode) {
          case 400:
            responseData["message"] = "Error[$statusCode]: Bad request";
            break;
          case 403:
            responseData["message"] =
                "Error[$statusCode]: Unauthorised response";
            break;
          default:
            responseData["message"] =
                "response failed with status: $statusCode";
        }
      }
      Map values = {};
      for (var key in responseData.keys) {
        if (key != "success" && key != "message") {
          values[key] = responseData[key];
        }
      }
      if (values.isEmpty) {
        return APIResponse<T>(
          responseData["success"] ?? false,
          responseData["message"] ?? "",
          statusCode,
          errors: responseData[errorsField],
          body: responseData,
        );
      } else if (values.length == 1) {
        return APIResponse(
          responseData["success"] ?? false,
          responseData["message"] ?? "",
          statusCode,
          errors: responseData[errorsField],
          body: responseData,
          value: values[values.keys.first],
        );
      } else {
        return APIResponse(
          responseData["success"] ?? false,
          responseData["message"] ?? "",
          statusCode,
          errors: responseData[errorsField],
          body: responseData,
          value: values as T,
        );
      }
    } catch (e) {
      String strBody = response.toString();
      String body = strBody.substring(
        0,
        strBody.length < 10 ? strBody.length : 10,
      );
      print("ERROR:" + e.toString());
      print("body: $body");
      return APIResponse(
        false,
        "body: $body...",
        statusCode,
        body: strBody,
      );
    }
  }
}
