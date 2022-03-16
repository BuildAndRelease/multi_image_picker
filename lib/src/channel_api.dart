import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

const MethodChannel channel = const MethodChannel('multi_image_picker');
enum FBMediaShowType { image, video, all }
enum FBMediaSelectType { all, video, image, singleType }
enum FBMediaThumbType { origin, thumb, file }

extension FBMediaShowTypeValue on FBMediaShowType {
  String nameString() {
    switch (this) {
      case FBMediaShowType.video:
        return "video";
      case FBMediaShowType.image:
        return "image";
      case FBMediaShowType.all:
        return "all";
      default:
        return "";
    }
  }
}

extension FBMediaSelectTypeValue on FBMediaSelectType {
  String nameString() {
    switch (this) {
      case FBMediaSelectType.all:
        return "selectAll";
      case FBMediaSelectType.image:
        return "selectImage";
      case FBMediaSelectType.video:
        return "selectVideo";
      case FBMediaSelectType.singleType:
        return "selectSingleType";
      default:
        return "";
    }
  }
}

extension FBMediaThumbTypeValue on FBMediaThumbType {
  String nameString() {
    switch (this) {
      case FBMediaThumbType.thumb:
        return "thumb";
      case FBMediaThumbType.origin:
        return "origin";
      case FBMediaThumbType.file:
        return "file";
      default:
        return "";
    }
  }
}

typedef MediaCallback = Function(Map params);

class MediaChannelApi {
  static MediaCallback? mediaCallback;
  static Future<void> init({callback: MediaCallback}) async {
    mediaCallback ??= callback;

    channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == "showCircleSendPage") {
        //TO DO
        mediaCallback?.call({});
      }
    });
  }
}
