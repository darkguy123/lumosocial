import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/common/managers/logger.dart';

class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class ApiService {
  static final shared = ApiService();
  final Map<CancelToken, http.Client> _activeClients = {};

  var header = {'apikey': '123'};

  Future<void> call({
    required String url,
    Map<String, dynamic>? param,
    CancelToken? cancelToken,
    required Function(Map<String, dynamic> response) completion,
  }) async {
    final client = http.Client();
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    Map<String, String> params = {};
    param?.removeWhere(
      (key, value) => value == null,
    );

    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = jsonEncode(value[i]);
        }
      } else {
        params[key] = "$value";
      }
    });

    Loggers.info("URL: $url");
    Loggers.info("Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: header,
        body: params,
      );

      if (cancelToken?.isCancelled ?? false) {
        if (kDebugMode) {
          Loggers.warning("Request cancelled: $url");
        }
        throw Exception('Request was cancelled');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final prettyString = const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);
        completion(decodedResponse);
      } else if (response.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${response.statusCode} - $url");
      } else {
        final errorBody = response.body;
        final errorMessage = _extractErrorMessage(errorBody);
        Loggers.error(errorMessage);
        // Handle HTTP errors
        throw Exception("HTTP Error: ${response.statusCode} - ${response.reasonPhrase}");
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      // Handle JSON decoding errors
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error: $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  String _extractErrorMessage(String responseBody) {
    final regex = RegExp(
      r'<!--\s*(.*?)\s*#0 ', // Matches everything between <!-- and #0
      dotAll: true,
    );
    final match = regex.firstMatch(responseBody);
    return match?.group(1)?.trim() ?? "Unknown error occurred: ${_shorten(responseBody)}";
  }

  /// Shortens the response body if no specific error is found
  String _shorten(String responseBody) {
    const maxLength = 100;
    return responseBody.length > maxLength ? "${responseBody.substring(0, maxLength)}..." : responseBody;
  }

  Future multiPartCallApi({
    required String url,
    Map<String, dynamic>? param,
    required Map<String, List<XFile?>> filesMap,
    Function(double percentage)? onProgress,
    CancelToken? cancelToken,
    required Function(Map<String, dynamic> response) completion,
  }) async {
    final client = http.Client();
    if (cancelToken != null) {
      _activeClients[cancelToken] = client;
    }

    final request = MultipartRequest(
      'POST',
      Uri.parse(url),
      onProgress: (bytes, totalBytes) {
        if (onProgress != null) {
          onProgress(bytes / totalBytes);
        }
      },
    );

    Map<String, String> params = {};
    param?.removeWhere(
      (key, value) => value == null,
    );
    param?.forEach((key, value) {
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          params['$key[$i]'] = jsonEncode(value[i]);
        }
      } else {
        params[key] = "$value";
      }
    });

    request.fields.addAll(params);
    request.headers.addAll(header);
    request.headers.addAll({'ContentType': 'multipart/form-data'});

    filesMap.forEach((keyName, files) {
      for (var xFile in files) {
        if (xFile != null && xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          Loggers.success('UDPALOED: $keyName, ${file.path}');
          final multipartFile = http.MultipartFile(
            keyName,
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: xFile.name,
          );
          request.files.add(multipartFile);
        }
      }
    });

    Loggers.info("URL: $url");
    Loggers.info("Parameters: ${params.isEmpty ? "Empty" : JsonEncoder.withIndent('  ').convert(params)}");

    try {
      final responseStream = await client.send(request);

      if (cancelToken?.isCancelled ?? false) {
        Loggers.warning("Request cancelled: $url");
        throw Exception('Request was cancelled');
      }

      final responseStr = await responseStream.stream.bytesToString();

      if (responseStream.statusCode >= 200 && responseStream.statusCode < 300) {
        final decodedResponse = jsonDecode(responseStr) as Map<String, dynamic>;
        final prettyString = const JsonEncoder.withIndent('  ').convert(decodedResponse);
        Loggers.info(prettyString);

        // Use the provided `fromJson` function to parse the response
        completion(decodedResponse);
      } else if (responseStream.statusCode == 404) {
        Loggers.error('Please check baseURL in const.dart file');
        throw Exception("URL Error: ${responseStream.statusCode} - $url");
      } else {
        final errorMessage = _extractErrorMessage(responseStr);
        Loggers.error(errorMessage);
        throw Exception("HTTP Error: ${responseStream.statusCode} - ${responseStream.reasonPhrase}");
      }
    } on HttpException {
      throw Exception('Could not connect to the server');
    } on FormatException catch (e) {
      Loggers.error("Invalid JSON format: ${e.message}");
      throw Exception("Invalid JSON format: ${e.message}");
    } on Exception catch (e) {
      Loggers.error("Unexpected error: $e");
      rethrow;
    } finally {
      _cleanupClient(cancelToken);
    }
  }

  void _cleanupClient(CancelToken? cancelToken) {
    if (cancelToken != null) {
      _activeClients[cancelToken]?.close();
      _activeClients.remove(cancelToken);
    }
  }

  Future<String?> downloadFile(String url, String fileName) async {
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Directory? directory = await (Platform.isAndroid ? getExternalStorageDirectory() : getApplicationDocumentsDirectory());
        String filePath = '${directory!.path}/$fileName';
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        Loggers.success("File downloaded to: $filePath");
        return filePath;
      } else {
        Loggers.error("Failed to download file.");
        return null;
      }
    } catch (e) {
      Loggers.error("Download error: $e");
      return null;
    }
  }
}

class MultipartRequest extends http.MultipartRequest {
  MultipartRequest(
    super.method,
    super.url, {
    this.onProgress,
  });

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        if (onProgress != null) {
          onProgress!(bytes, total);
        }
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
