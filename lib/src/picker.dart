import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class MultiImagePicker {
  static const MethodChannel _channel =
      const MethodChannel('multi_image_picker');
  static final Map<String, Uint8List> _cacheThumbData = Map();

  /// Invokes the multi image picker selector.
  ///
  /// You must provide [maxImages] option, which will limit
  /// the number of images that the user can choose. On iOS
  /// you can pass also [cupertinoOptions] parameter which should be
  /// an instance of [CupertinoOptions] class. It allows you
  /// to customize the look of the image picker. On Android
  /// you can pass the [materialOptions] parameter, which should
  /// be an instance of [MaterialOptions] class.
  /// As from version  2.1.40 a new parameter [enableCamera]
  /// was added, which allows the user to take a picture
  /// directly from the gallery.
  ///
  /// If you would like to present the picker with pre selected
  /// photos, you can pass [selectedAssets] with List of Asset
  /// objects picked previously from the picker.
  ///
  /// This method returns list of [Asset] objects. Because
  /// they are just placeholders containing the actual
  /// identifier to the image, not the image itself you can
  /// pick thousands of images at a time, with no performance
  /// penalty. How to request the original image or a thumb
  /// you can refer to the docs for the Asset class.
  static Future<Map<dynamic, dynamic>> pickImages({
    @required int maxImages,
    bool thumb = true,
    String defaultAsset = "",
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
      {bool thumb = true, List<String> selectedAssets = const []}) async {
    try {
      final List<dynamic> images = await _channel.invokeMethod(
          'requestMediaData',
          <String, dynamic>{'thumb': thumb, 'selectedAssets': selectedAssets});
      var assets = List<Asset>();
      for (var item in images) {
        var asset;
        final String fileType = item['fileType'];
        final String errorCode = item['errorCode'];
        if (fileType == null || fileType.isEmpty) {
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
    }
  }

  static Future<String> requestFileSize(String identifier) async {
    try {
      return await _channel.invokeMethod(
          'requestFileSize', <String, dynamic>{'identifier': identifier});
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<dynamic> requestFileDimen(String identifier) async {
    try {
      return await _channel.invokeMethod(
          'requestFileDimen', <String, dynamic>{'identifier': identifier});
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
      {List<String> selectedAssets}) async {
    try {
      final List<dynamic> images = await _channel.invokeMethod(
          'fetchMediaInfo', <String, dynamic>{
        'limit': limit,
        'offset': offset,
        'selectedAssets': selectedAssets
      });
      var assets = List<Asset>();
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
        return _cacheThumbData[identifier];
      } else {
        Uint8List data = await _channel.invokeMethod('fetchMediaThumbData',
            <String, dynamic>{'identifier': identifier, 'fileType': fileType});
        if (_cacheThumbData.length > 500) {
          _cacheThumbData.remove(_cacheThumbData.keys.first);
        }
        if (data != null) {
          _cacheThumbData[identifier] = data;
        }
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
      return _cacheThumbData[identifier];
    } on Exception catch (e) {
      print(e);
      return Uint8List(0);
    }
  }
}
