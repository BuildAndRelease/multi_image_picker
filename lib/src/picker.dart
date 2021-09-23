import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class MultiImagePicker {
  static const MethodChannel _channel =
      const MethodChannel('multi_image_picker');
  static final Map<String, Uint8List> _cacheThumbData = Map();

  // selectType: selectAll selectVideo  selectImage selectSingleType
  static Future<Map<dynamic, dynamic>> pickImages({
    int maxImages = 9,
    bool thumb = true,
    String defaultAsset = "",
    String selectType = "",
    String doneButtonText = '',
    List<String> selectedAssets = const [],
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) async {
    try {
      final Map<dynamic, dynamic> medias = await _channel.invokeMethod(
        'pickImages',
        <String, dynamic>{
          'maxImages': maxImages,
          'thumb': thumb,
          'selectType': selectType,
          'doneButtonText': doneButtonText,
          'iosOptions': cupertinoOptions.toJson(),
          'androidOptions': materialOptions.toJson(),
          'defaultAsset': defaultAsset,
          'selectedAssets': selectedAssets,
        },
      );
      return medias;
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<List<Asset>> requestMediaData(
      {bool thumb = true,
      List<String> selectedAssets = const [],
      List<Asset> defalutValue = const []}) async {
    try {
      if (!Platform.isIOS && !Platform.isAndroid) return defalutValue;
      final List<dynamic> images = await _channel.invokeMethod(
          'requestMediaData',
          <String, dynamic>{'thumb': thumb, 'selectedAssets': selectedAssets});
      List<Asset> assets = [];
      for (var item in images) {
        var asset;
        final String fileType = item['fileType'] ?? "";
        final String errorCode = item['errorCode'];
        if (fileType.isEmpty) {
          asset = Asset(item['identifier'], '', '', 0.0, 0.0, '',
              errorCode: errorCode);
        } else if (fileType.contains('image')) {
          asset = Asset(
            item['identifier'],
            item['filePath'],
            item['name'],
            item['width'],
            item['height'],
            item['fileType'],
            checkPath: item['checkPath'],
          );
        } else if (fileType.contains('video')) {
          asset = Asset(
            item['identifier'],
            item['filePath'],
            item['name'],
            item['width'],
            item['height'],
            item['fileType'],
            duration: item['duration'],
            thumbFilePath: item['thumbPath'],
            thumbName: item['thumbName'],
            thumbHeight: item['thumbHeight'],
            thumbWidth: item['thumbWidth'],
          );
        }
        _cacheThumbData.remove(item['identifier']);
        assets.add(asset);
      }
      return assets;
    } on PlatformException catch (e) {
      throw e;
    }
  }

// example: fileType: video/mp4 image/jpg image/png image/gif
  static Future<List<Asset>> requestCompressMedia(bool thumb,
      {String fileType = "",
      List<String> fileList = const [],
      List<Asset> defalutValue = const []}) async {
    if (!Platform.isIOS && !Platform.isAndroid) return defalutValue;
    try {
      final List<dynamic> images = await _channel.invokeMethod(
          'requestCompressMedia', <String, dynamic>{
        'thumb': thumb,
        'fileType': fileType,
        'fileList': fileList
      });
      List<Asset> assets = [];
      for (var item in images) {
        var asset;
        final String errorCode = item['errorCode'];
        if ((errorCode?.isNotEmpty ?? false) && errorCode != "0") {
          asset = Asset('', '', '', 0.0, 0.0, '', errorCode: errorCode);
        } else if (fileType.contains('image')) {
          asset = Asset(
            item['identifier'],
            item['filePath'],
            item['name'],
            item['width'],
            item['height'],
            item['fileType'],
            checkPath: item['checkPath'],
          );
        } else if (fileType.contains('video')) {
          asset = Asset(
            item['identifier'],
            item['filePath'],
            item['name'],
            item['width'],
            item['height'],
            item['fileType'],
            duration: item['duration'],
            thumbFilePath: item['thumbPath'],
            thumbName: item['thumbName'],
            thumbHeight: item['thumbHeight'],
            thumbWidth: item['thumbWidth'],
          );
        }
        assets.add(asset);
      }
      return assets;
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<Asset> requestTakePicture(
      {String themeColor = "0xFF00CC00"}) async {
    try {
      final dynamic item = await _channel.invokeMethod(
          'requestTakePicture', <String, dynamic>{'themeColor': themeColor});
      var asset = Asset(
        item['identifier'],
        item['filePath'],
        item['name'],
        item['width'],
        item['height'],
        item['fileType'],
        checkPath: item['checkPath'],
        duration: item['duration'],
        thumbFilePath: item['thumbPath'],
        thumbName: item['thumbName'],
        thumbHeight: item['thumbHeight'],
        thumbWidth: item['thumbWidth'],
      );
      return asset;
    } on PlatformException catch (e) {
      throw e;
    } on Exception catch (e) {
      print(e);
    }
  }

  // static Future<String> requestFileSize(String identifier) async {
  //   try {
  //     return await _channel.invokeMethod(
  //         'requestFileSize', <String, dynamic>{'identifier': identifier});
  //   } on PlatformException catch (e) {
  //     throw e;
  //   }
  // }

  static Future<dynamic> requestFileDimen(String identifier) async {
    try {
      return await _channel.invokeMethod(
          'requestFileDimen', <String, dynamic>{'identifier': identifier});
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<dynamic> cachedVideoPath(String url) async {
    try {
      return await _channel
          .invokeMethod('cachedVideoPath', <String, dynamic>{'url': url});
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<String> requestThumbDirectory() async {
    try {
      return await _channel.invokeMethod('requestThumbDirectory');
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<List<Asset>> fetchMediaInfo(int offset, int limit,
      {List<String> selectedAssets = const []}) async {
    try {
      final List<dynamic> images = await _channel.invokeMethod(
          'fetchMediaInfo', <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'selectedAssets': selectedAssets
      });
      List<Asset> assets = [];
      for (var item in images) {
        var asset = Asset(item['identifier'], item['filePath'], item['name'],
            item['width'], item['height'], item['fileType'],
            duration: item['duration']);
        assets.add(asset);
      }
      return assets;
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<Uint8List> fetchMediaThumbData(
      String identifier, String fileType) async {
    try {
      if (_cacheThumbData.containsKey(identifier)) {
        return _cacheThumbData[identifier] ?? Uint8List(0);
      } else {
        Uint8List data = await _channel.invokeMethod(
                'fetchMediaThumbData', <String, dynamic>{
              'identifier': identifier,
              'fileType': fileType
            }) ??
            Uint8List(0);
        if (_cacheThumbData.length > 500) {
          _cacheThumbData.remove(_cacheThumbData.keys.first);
        }
        _cacheThumbData[identifier] = data;
        return data;
      }
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static bool containCacheData(String identifier) {
    return _cacheThumbData.containsKey(identifier);
  }

  static Uint8List fetchCacheThumbData(String identifier) {
    try {
      return _cacheThumbData[identifier] ?? Uint8List(0);
    } on Exception catch (e) {
      print(e);
      return Uint8List(0);
    }
  }
}
