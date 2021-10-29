import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

enum MediaShowType { image, video, all }
enum MediaSelectType { all, video, image, singleType }

class MultiImagePicker {
  static const MethodChannel _channel =
      const MethodChannel('multi_image_picker');
  static final Map<String, Uint8List> _cacheThumbData = Map();

  // 弹出原生选择界面,返回选择的媒体信息
  static Future<Map<dynamic, dynamic>> pickImages({
    int maxImages = 9,
    bool thumb = true,
    String defaultAsset = "",
    MediaSelectType mediaSelectType = MediaSelectType.all,
    List<String> selectedAssets = const [],
    String doneButtonText = '',
    MediaShowType mediaShowType = MediaShowType.all,
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) async {
    try {
      final Map<dynamic, dynamic> medias = await _channel.invokeMethod(
        'pickImages',
        <String, dynamic>{
          'maxImages': maxImages,
          'thumb': thumb,
          'mediaSelectTypes': _mediaSelectTypeToString(mediaSelectType),
          'doneButtonText': doneButtonText,
          'iosOptions': cupertinoOptions.toJson(),
          'androidOptions': materialOptions.toJson(),
          'defaultAsset': defaultAsset,
          'mediaShowTypes': _mediaShowTypeToString(mediaShowType),
          'selectedAssets': selectedAssets,
        },
      );
      return medias;
    } on PlatformException catch (e) {
      throw e;
    }
  }

  static String _mediaShowTypeToString(MediaShowType type) {
    switch (type) {
      case MediaShowType.video:
        return "video";
      case MediaShowType.image:
        return "image";
      case MediaShowType.all:
        return "all";
      default:
        return "";
    }
  }

  static String _mediaSelectTypeToString(MediaSelectType type) {
    switch (type) {
      case MediaSelectType.all:
        return "selectAll";
      case MediaSelectType.image:
        return "selectImage";
      case MediaSelectType.video:
        return "selectVideo";
      case MediaSelectType.singleType:
        return "selectSingleType";
      default:
        return "";
    }
  }

  // 获取指定媒体信息 selectedAssets 为指定媒体的Identify
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

  // 压缩指定的媒体
  // param:
  // fileType: video/mp4 image/jpg image/png image/gif
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

  //根据identifier来请求媒体的宽高
  static Future<dynamic> requestFileDimen(String identifier) async {
    try {
      return await _channel.invokeMethod(
          'requestFileDimen', <String, dynamic>{'identifier': identifier});
    } on PlatformException catch (e) {
      throw e;
    }
  }

  //是否缓存了视频在本地磁盘
  static Future<dynamic> cachedVideoPath(String url) async {
    try {
      return await _channel
          .invokeMethod('cachedVideoPath', <String, dynamic>{'url': url});
    } on PlatformException catch (e) {
      throw e;
    }
  }

  //获取压缩文件存放的目录
  static Future<String> requestThumbDirectory() async {
    try {
      return await _channel.invokeMethod('requestThumbDirectory');
    } on PlatformException catch (e) {
      throw e;
    }
  }

  // 获取手机数据库中的媒体信息,或者获取指定identifier的媒体信息
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

  // 获取指定媒体的缩略图或者视频封面
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

  // 是否缓存了某个媒体的封面
  static bool containCacheData(String identifier) {
    return _cacheThumbData.containsKey(identifier);
  }

  // 获取缓存的某个媒体封面
  static Uint8List fetchCacheThumbData(String identifier) {
    try {
      return _cacheThumbData[identifier] ?? Uint8List(0);
    } on Exception catch (e) {
      print(e);
      return Uint8List(0);
    }
  }
}
