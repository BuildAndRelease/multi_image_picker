# multi_image_picker

这是一个图片、视频的选择&压缩flutter插件

## Getting Started

在flutter工程中添加依赖

```dart
    multi_image_picker:
        git: https://github.com/BuildAndRelease/multi_image_picker.git
```

API 文件是picker.dart

此API弹出相册选择框，返回用户选择的媒体ID。
selectType是选择模式
selectAll：图片视频均可选择
selectVideo：仅能选择视频
selectImage：仅能选择图片
selectSingleType：如果用户第一此次选择的是视频则仅能选择视频、如果用户第一此选择的是图片则仅能选择图片
```dart
  // selectType: selectAll selectVideo selectImage selectSingleType
  static Future<Map<dynamic, dynamic>> pickImages({
    @required int maxImages,
    bool thumb = true,
    String defaultAsset = "",
    String selectType = "",
    String doneButtonText = '',
    List<String> selectedAssets = const [],
    CupertinoOptions cupertinoOptions = const CupertinoOptions(),
    MaterialOptions materialOptions = const MaterialOptions(),
  })
```

此API传入需要压缩的媒体ID，返回压缩后的媒体类Asset。
```dart
  static Future<List<Asset>> requestMediaData(
      {bool thumb = true, List<String> selectedAssets = const []})
```

此API仿照微信，点击拍照长按录视频并返回媒体类Asset。
```dart
  static Future<Asset> requestTakePicture(
      {String themeColor = "0xFF00CC00"})
```

此API传入媒体ID，返回媒体大小。
```dart
  static Future<String> requestFileSize(String identifier)
```

此API传入媒体ID，返回媒体Size。
```dart
  static Future<dynamic> requestFileDimen(String identifier)
```

此API返回压缩有的图片保存文件夹。
```dart
  static Future<String> requestThumbDirectory()
```

此API返回手机相册内的媒体信息列表
```dart
  static Future<List<Asset>> fetchMediaInfo(int offset, int limit,
      {List<String> selectedAssets})
```

此API返回手机相册内的媒体缩率图
```dart
  static Future<Uint8List> fetchMediaThumbData(
      String identifier, String fileType)
```

此API返回判断是否已经缓存了某个媒体的缩率图
```dart
  static bool containCacheData(String identifier)
```

此API返回缓存中的媒体缩率图
```dart
  fetchCacheThumbData(String identifier)
```
