//
//  MediaEditorImp.swift
//  multi_image_picker
//
//  Created by amzwin on 2022/3/16.
//

import Foundation
import Flutter
import UIKit
import Photos
import KTVHTTPCache

class MediaEditorImp{
    public class func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "editor.showMediaPicker":
            result("editor.showMediaPicker");
            break
        case "editor.reEditorMedia":
            result("editor.reEditorMedia");
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
