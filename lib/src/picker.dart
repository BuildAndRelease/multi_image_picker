import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:multi_image_picker/src/exceptions.dart';

class MultiImagePicker {
  static const MethodChannel _channel = const MethodChannel('multi_image_picker');
  static final List<Asset> _cacheMediaData = List();
  static bool isCacheMediaData = false;

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
  static Future<List<Asset>> pickImages({
    @required int maxImages,
    int qualityOfImage = 50,
    int maxWidth = 300,
    int maxHeight = 300,
    bool enableCamera = false,
    List<String> selectedAssets = const [],
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) async {
    assert(maxImages != null);

    if (maxImages != null && maxImages < 0) {
      throw new ArgumentError.value(maxImages, 'maxImages cannot be negative');
    }

    try {
      final List<dynamic> images = await _channel.invokeMethod(
        'pickImages',
        <String, dynamic>{
          'maxImages': maxImages,
          'qualityOfImage': qualityOfImage,
          'maxHeight': maxHeight,
          'maxWidth': maxWidth,
          'enableCamera': enableCamera,
          'iosOptions': cupertinoOptions.toJson(),
          'androidOptions': materialOptions.toJson(),
          'selectedAssets': selectedAssets,
        },
      );
      var assets = List<Asset>();
      for (var item in images) {
        var asset;
        if (item['fileType'] == 'image') {
        asset = Asset(
          item['identifier'],
          item['filePath'],
          item['name'],
          item['width'],
          item['height'],
          item['fileType'],
        );
        }else if (item['fileType'] == 'video') {
        asset = Asset(
          item['identifier'],
          item['filePath'],
          item['name'],
          item['width'],
          item['height'],
          item['fileType'],
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
      switch (e.code) {
        case "CANCELLED":
          throw NoImagesSelectedException(e.message);
        default:
          throw e;
      }
    }
  }

static Future<List<Asset>> requestMediaData({
    int qualityOfImage = 80,
    int maxWidth = 750,
    int maxHeight = 1334,
    bool thumb = true,
    List<String> selectedAssets = const []
  }) async {
    try {
      final List<dynamic> images = await _channel.invokeMethod(
        'requestMediaData',
        <String, dynamic>{
          'qualityOfImage': qualityOfImage,
          'maxHeight': maxHeight,
          'maxWidth': maxWidth,
          'thumb': thumb,
          'selectedAssets': selectedAssets});
      var assets = List<Asset>();
      for (var item in images) {
        var asset;
        if (item['fileType'] == 'image') {
        asset = Asset(
          item['identifier'],
          item['filePath'],
          item['name'],
          item['width'],
          item['height'],
          item['fileType'],
        );
        }else if (item['fileType'] == 'video') {
        asset = Asset(
          item['identifier'],
          item['filePath'],
          item['name'],
          item['width'],
          item['height'],
          item['fileType'],
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
      switch (e.code) {
        case "CANCELLED":
          throw NoImagesSelectedException(e.message);
        default:
          throw e;
      }
    }
  }

  static Future<void> cacheMediaData() async {
    try {
      final List<dynamic> images = await _channel.invokeMethod('fetchMediaInfo', <String, dynamic>{
        'pageNum': -1,
        'pageSize': -1
        });
      for (var item in images) {
        var asset = Asset(
          item['identifier'],
          item['filePath'],
          item['name'],
          item['width'],
          item['height'],
          item['fileType'],
          duration: item['duration']
        );
        _cacheMediaData.add(asset);
      }
      if (_cacheMediaData.length > 0) {
        isCacheMediaData = true;
      }else {
        isCacheMediaData = false;
      }
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<List<Asset>> fetchMediaInfo(int pageNum, int pageSize) async {
    try {
      if (isCacheMediaData) {
        if (pageNum == -1 && pageSize == -1) {
          return _cacheMediaData;
        }else {
          int start = (pageNum - 1) * pageSize;
          int end = pageNum * pageSize;
          int cachedLength = _cacheMediaData.length;
          if (start >= cachedLength) {
            return List();
          }else {
            return _cacheMediaData.sublist(start, min(end, cachedLength));
          }
        }
      }else {
        final List<dynamic> images = await _channel.invokeMethod('fetchMediaInfo', <String, dynamic>{
        'pageNum': pageNum,
        'pageSize': pageSize
        });
        var assets = List<Asset>();
        for (var item in images) {
        var asset = Asset(
          item['identifier'],
          item['filePath'],
          item['name'],
          item['width'],
          item['height'],
          item['fileType'],
          duration: item['duration']
        );
        assets.add(asset);
        }
        if (assets.length > 0 && pageNum == -1 && pageSize == -1) {
          _cacheMediaData.addAll(assets);
          isCacheMediaData = true;
        }
        return assets;
      }
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static Future<Uint8List> fetchMediaThumbData(String identifier, String fileType) async {
    try {
        return await _channel.invokeMethod('fetchMediaThumbData', <String, dynamic>{'identifier': identifier, 'fileType': fileType});
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static void clearMediaDataCache() {
    _cacheMediaData.clear();
    isCacheMediaData = false;
  }

}
