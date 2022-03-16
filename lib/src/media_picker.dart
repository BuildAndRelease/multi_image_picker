import 'package:flutter/services.dart';

import 'channel_api.dart';
import 'cupertino_options.dart';
import 'material_options.dart';

class MediaPicker {
  /*
  展示编辑图片选择器
  约定所有invokeMethod方法前面加editor。 eg. editor.showMediaPicker
   */
  static Future<Map<dynamic, dynamic>?> showMediaPicker({
    int maxImages = 9,
    FBMediaThumbType thumbType = FBMediaThumbType.thumb,
    String defaultAsset = "",
    FBMediaSelectType mediaSelectType = FBMediaSelectType.all,
    List<String> selectedAssets = const [],
    String doneButtonText = '',
    FBMediaShowType mediaShowType = FBMediaShowType.all,
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  }) async {
    try {
      final Map<dynamic, dynamic>? medias = await channel.invokeMethod(
        'editor.showMediaPicker',
        <String, dynamic>{
          'maxImages': maxImages,
          'thumb': thumbType.nameString(),
          'mediaSelectTypes': mediaSelectType.nameString(),
          'doneButtonText': doneButtonText,
          'iosOptions': cupertinoOptions.toJson(),
          'androidOptions': materialOptions.toJson(),
          'defaultAsset': defaultAsset,
          'mediaShowTypes': mediaShowType.nameString(),
          'selectedAssets': selectedAssets,
        },
      );
      return medias;
    } on PlatformException catch (e) {
      throw e;
    }
  }

  /*
  重新编辑某一个资源
   */
  static Future<Map<dynamic, dynamic>?> reEditorMedia({params: Map}) async {
    try {
      final Map<dynamic, dynamic>? medias = await channel.invokeMethod(
        'editor.reEditorMedia',
        params,
      );
      return medias;
    } on PlatformException catch (e) {
      throw e;
    }
  }
}
