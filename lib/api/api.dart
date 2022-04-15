import 'package:http/http.dart' as http;

import '../storage_database.dart';
import 'request.dart';
import 'response.dart';

class StorageAPI {
  final StorageDatabase storageDatabase;
  final String apiUrl;
  // final bool cachOnOffline;
  // final Function(APIResponse respnse)? onReRequestResponse;

  late APIRequest apiRequest;

  StorageAPI({
    required this.storageDatabase,
    required this.apiUrl,
    Map<String, String> headers = const {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    },
    // this.cachOnOffline = true,
    // this.onReRequestResponse,
  }) {
    apiRequest = APIRequest(
      storageDatabase,
      apiUrl,
      headers,
    );
    // storageDatabase.collection('api').set({});
  }

  Future<APIResponse<T>> request<T>(
    String target,
    RequestType type, {
    Map<String, dynamic>? data,
    List<http.MultipartFile> files = const [],
    Function(int bytes, int totalBytes)? onFilesUpload,
    bool log = false,
    Map<String, String> headers = const {},
    bool appendHeader = true,
    // Function(String reqId)? onNoConnection,
    Function()? onNoConnection,
    String errorsField = 'errors',
  }) =>
      apiRequest.send(
        target,
        type,
        data: data,
        files: files,
        onFilesUpload: onFilesUpload,
        log: log,
        headers: headers,
        appendHeader: appendHeader,
        onNoConnection: () async {
          // if (cachOnOffline) {
          //   var reqId = DateTime.now().millisecondsSinceEpoch;
          // await storageDatabase.document('api/requests').set({
          //   '$reqId': {
          //     'id': reqId,
          //     'target': target,
          //     'headers': headers,
          //     'type': type.type,
          //     'data': data,
          //   }
          // });
          // if (onNoConnection != null) onNoConnection('$reqId');
          if (onNoConnection != null) onNoConnection();
          // }
        },
        errorsField: errorsField,
      );

  // Future<APIResponse<T>?> resendRequest<T>(String requestId) async {
  //   StorageDocument doc =
  //       storageDatabase.document('api/requests').document(requestId);
  //   Map requestData = await doc.get();
  //   APIResponse<T> res = await apiRequest.send(
  //     requestData['target'],
  //     RequestType.fromString(requestData['type'])!,
  //     headers: requestData['headers'],
  //     data: requestData['data'],
  //   );
  //   if (res.statusCode != 400) await doc.delete();
  //   return res;
  // }

  // Future resendRequests({
  //   List ids = const [],
  //   Function(APIResponse respnse)? onResponse,
  // }) async {
  //   if (ids.isEmpty) {
  //     ids =
  //         Map.from((await storageDatabase.document('api/requests').get() ?? {}))
  //             .keys
  //             .toList();
  //   }
  //   for (String id in ids) {
  //     await resendRequest(id);
  //   }
  // }

  Future clear() async {
    storageDatabase.onClear.add(() async {
      await storageDatabase.collection('api').set({});
    });
    await storageDatabase.collection('api').delete();
  }
}
