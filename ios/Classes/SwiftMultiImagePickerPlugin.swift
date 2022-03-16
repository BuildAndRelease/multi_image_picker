import Flutter
import UIKit
import Photos
import KTVHTTPCache

public class SwiftMultiImagePickerPlugin: NSObject, FlutterPlugin, UIAlertViewDelegate {
    var imagesResult: FlutterResult?
    var messenger: FlutterBinaryMessenger;

    static var methodChannel:FlutterMethodChannel?
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger;
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "multi_image_picker", binaryMessenger: registrar.messenger())
        methodChannel = channel;
        let instance = SwiftMultiImagePickerPlugin.init(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let callMethod = call.method;
        if(callMethod.contains("editor.")){
            MediaEditorImp.handleMethodCall(call, result: result)
            return
        }
        
        MediaPickerImp.handleMethodCall(call, result: result)
    }
}
