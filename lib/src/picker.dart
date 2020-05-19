import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:multi_image_picker/src/exceptions.dart';

class MultiImagePicker {
  static const MethodChannel _channel = const MethodChannel('multi_image_picker');

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
    List<Asset> selectedAssets = const [],
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
          'selectedAssets': selectedAssets
              .map(
                (Asset asset) => asset.identifier,
              )
              .toList(),
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
}
