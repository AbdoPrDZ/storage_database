import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import '../src/storage_database_exception.dart';
import 'storage_explorer.dart';

class ExplorerNetworkFiles {
  final StorageExplorer storageExplorer;
  final ExplorerDirectory networkDirFiles;

  ExplorerNetworkFiles(this.storageExplorer, this.networkDirFiles) {
    _instance = this;
  }

  static ExplorerNetworkFiles? _instance;

  static bool get hasInstance => _instance != null;

  static ExplorerNetworkFiles get instance {
    if (!hasInstance) {
      throw const StorageDatabaseException(
        'ExplorerNetworkFiles instance has not initialized yet',
      );
    }

    return _instance!;
  }

  String encodeUrl(String url) => utf8.fuse(base64).encode(url);

  String decodeUrl(String code) => utf8.fuse(base64).decode(code);

  Future<ExplorerFile?> file(
    String url, {
    bool refresh = false,
    Map<String, String> headers = const {},
    bool getOldOnError = false,
    bool log = false,
  }) async {
    String encodedUrl = encodeUrl(url);
    ExplorerFile file = networkDirFiles.file(encodedUrl);

    if (log) {
      dev.log('[StorageExplorer.NetworkFile] reqUrl: $url');
      dev.log('[StorageExplorer.NetworkFile] reqEncodedUrl: $encodedUrl');
    }

    if (!file.exists || refresh) {
      if (log) dev.log('[StorageExplorer.NetworkFile] reqHeaders: $headers');

      Uint8List? fileData = await downloadFile(
        Uri.parse(url),
        log: log,
        headers: headers,
      );

      if (fileData != null) {
        await file.setBytes(fileData);
      } else if (!file.exists && !getOldOnError) {
        return null;
      }
    }
    return file;
  }

  Future<Uint8List?> downloadFile(
    Uri uri, {
    Map<String, String> headers = const {},
    bool log = false,
  }) async {
    http.Response response = (await http.get(uri, headers: headers));

    if (response.statusCode == 200) {
      if (log) dev.log("[StorageExplorer.NetworkFile] success");

      return response.bodyBytes;
    } else {
      if (log) {
        dev.log(
          "[StorageExplorer.NetworkFile] resCode: ${response.statusCode}",
        );
        dev.log("[StorageExplorer.NetworkFile] resBody: ${response.body}");
      }

      return null;
    }
  }

  Widget networkImage(
    String url, {
    double? width,
    double? height,
    double? borderRadius,
    BoxFit fit = BoxFit.cover,
    Color backgroundColor = const Color.fromARGB(255, 168, 168, 168),
    Color baseColor = const Color.fromARGB(255, 168, 168, 168),
    Color highlightColor = const Color.fromARGB(255, 236, 236, 236),
    Color errorIconColor = const Color.fromARGB(255, 236, 236, 236),
    Map<String, String> headers = const {},
    bool refresh = false,
    bool getOldOnError = false,
    bool log = false,
  }) => ExplorerNetworkImage(
    explorerNetworkFiles: this,
    url: url,
    width: width,
    height: height,
    borderRadius: borderRadius,
    fit: fit,
    backgroundColor: backgroundColor,
    baseColor: baseColor,
    errorIconColor: errorIconColor,
    headers: headers,
    highlightColor: highlightColor,
    refresh: refresh,
    getOldOnError: getOldOnError,
    log: log,
  );

  Future clear() => networkDirFiles.clear();
}

class ExplorerNetworkImage extends StatefulWidget {
  final String url;
  final ExplorerNetworkFiles explorerNetworkFiles;
  final double? width, height, borderRadius;
  final EdgeInsets? margin, padding;
  final BoxFit fit;
  final Map<String, String> headers;
  final bool refresh, getOldOnError, log;
  final Color baseColor, highlightColor, errorIconColor, backgroundColor;
  final Color? borderColor;
  final bool setItInDecoration;

  const ExplorerNetworkImage({
    super.key,
    required this.url,
    required this.explorerNetworkFiles,
    this.headers = const {},
    this.refresh = false,
    this.getOldOnError = false,
    this.log = false,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.baseColor = const Color(0xFFA8A8A8),
    this.highlightColor = const Color(0xFFECECEC),
    this.errorIconColor = const Color(0xFFECECEC),
    this.backgroundColor = Colors.transparent,
    this.borderColor,
    this.margin,
    this.padding,
    this.setItInDecoration = true,
  });

  @override
  createState() => _ExplorerNetworkImageState();
}

class _ExplorerNetworkImageState extends State<ExplorerNetworkImage> {
  Future<File?> getImage() async => (await widget.explorerNetworkFiles.file(
    widget.url,
    headers: widget.headers,
  ))?.ioFile;

  @override
  Widget build(BuildContext context) => FutureBuilder<File?>(
    future: getImage(),
    builder: (context, snapshot) => Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
        color: widget.backgroundColor,
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!)
            : null,
        image: widget.setItInDecoration && snapshot.hasData
            ? DecorationImage(image: FileImage(snapshot.data!), fit: widget.fit)
            : null,
      ),
      child: snapshot.connectionState == ConnectionState.waiting
          ? Shimmer.fromColors(
              baseColor: widget.baseColor,
              highlightColor: widget.highlightColor,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
                  color: Colors.grey,
                ),
              ),
            )
          : !widget.setItInDecoration && snapshot.hasData
          ? Image.file(snapshot.data!)
          : widget.setItInDecoration && !snapshot.hasData
          ? Icon(
              Icons.broken_image,
              color: widget.errorIconColor,
              size: widget.width != null || widget.height != null
                  ? min(widget.width ?? 9e9, widget.height ?? 9e9) * 0.6
                  : 50,
            )
          : null,
    ),
  );
}
