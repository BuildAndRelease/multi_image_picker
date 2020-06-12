class Asset {
  /// The resource identifier
  String _identifier;

  /// The resource identifier
  String _filePath;

  /// The resource file name
  String _name;

  /// Original image width
  double _originalWidth;

  /// Original image height
  double _originalHeight;

  String _fileType;

  double duration = 0.0;

  String thumbFilePath = "";

  String thumbName = "";

  double thumbWidth = 0.0;

  double thumbHeight = 0.0;

  String url = "";

  String hash = "";

  Asset(
    this._identifier,
    this._filePath,
    this._name,
    this._originalWidth,
    this._originalHeight,
    this._fileType,
    {this.thumbFilePath, this.thumbName, this.thumbWidth, this.thumbHeight, this.duration, this.hash, this.url}
  );

  /// Returns the original image width
  double get originalWidth {
    return _originalWidth;
  }

  /// Returns the original image height
  double get originalHeight {
    return _originalHeight;
  }

  /// Returns true if the image is landscape
  bool get isLandscape {
    return _originalWidth > _originalHeight;
  }

  /// Returns true if the image is Portrait
  bool get isPortrait {
    return _originalWidth < _originalHeight;
  }

  /// Returns the image identifier
  String get identifier {
    return _identifier;
  }

  /// Returns the image thumb
  String get filePath {
    return _filePath;
  }

  /// Returns the image name
  String get name {
    return _name;
  }

  String get fileType {
     return _fileType;
  }

  Map toJsonMap() {
    Map assetInfo = {};
    assetInfo['identifier'] = identifier;
    assetInfo['filePath'] = filePath;
    assetInfo['name'] = name;
    assetInfo['originalWidth'] = originalWidth;
    assetInfo['originalHeight'] = originalHeight;
    assetInfo['fileType'] = fileType;
    assetInfo['duration'] = duration;
    assetInfo['thumbFilePath'] = thumbFilePath;
    assetInfo['thumbHeight'] = thumbHeight;
    assetInfo['thumbWidth'] = thumbWidth;
    assetInfo['thumbName'] = thumbName;
    assetInfo['url'] = url;
    assetInfo['hash'] = hash;
    return assetInfo;
  }

  factory Asset.fromJson(Map<String, dynamic> srcJson) {
    return Asset(srcJson['identifier'], srcJson['filePath'], srcJson['name'], srcJson['originalWidth'], srcJson['originalHeight'], srcJson['fileType'],
    duration: srcJson['duration'], thumbFilePath: srcJson['thumbFilePath'], thumbHeight: srcJson['thumbHeight'], thumbWidth: srcJson['thumbWidth'], 
    thumbName: srcJson['thumbName'], url: srcJson['url'], hash: srcJson['hash']);
  }
}
