import 'dart:async';

import 'package:flutter/services.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class Asset {
  /// The resource identifier
  String _identifier;

  /// The resource identifier
  String _filePath;

  /// The resource file name
  String _name;

  /// Original image width
  int _originalWidth;

  /// Original image height
  int _originalHeight;

  Asset(
    this._identifier,
    this._filePath,
    this._name,
    this._originalWidth,
    this._originalHeight,
  );

  /// The BinaryChannel name this asset is listening on.
  String get _channel {
    return 'multi_image_picker/image/$_identifier';
  }

  String get _thumbChannel => '$_channel.thumb';

  String get _originalChannel => '$_channel.original';

  /// Returns the original image width
  int get originalWidth {
    return _originalWidth;
  }

  /// Returns the original image height
  int get originalHeight {
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
  
  /// Requests the original image meta data
  Future<Metadata> get metadata {
    return MultiImagePicker.requestMetadata(_identifier);
  }

  @Deprecated(
    'This method will be deprecated in the next major release. Please use metadata getter instead.',
  )
  Future<Metadata> requestMetadata() {
    return metadata;
  }
}
