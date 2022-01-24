import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:multi_image_picker_example/DemoLocalizations.dart';

import 'DemoLocalizationsDelegate.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        DemoLocalizationsDelegate.delegate,
      ],
      supportedLocales: [
        const Locale('en'), // English
        const Locale('he', 'IL'), // Hebrew
        const Locale.fromSubtags(
            languageCode: 'zh'), // Chinese *See Advanced Locales below*
      ],
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Asset> images = List<Asset>();
  String _error = 'No Error Dectected';

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text(DemoLocalizations.of(context).titleBarTitle),
      ),
      body: Column(
        children: <Widget>[
          Center(child: Text('Error: $_error')),
          RaisedButton(
            child: Text(DemoLocalizations.of(context).imagePick),
            onPressed: loadAssets,
          ),
          ElevatedButton(
              onPressed: () async {
                final dir = await MultiImagePicker.requestThumbDirectory();
                print('图片缓存文件夹dir: $dir');
              },
              child: Text('图片缓存文件夹')),
          ElevatedButton(
              onPressed: () async {
                final dir = await MultiImagePicker.cachedVideoDirectory();
                print('视频缓存文件夹: $dir');
              },
              child: Text('视频缓存文件夹')),
          Expanded(
            child: buildGridView(),
          )
        ],
      ),
    );
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        // return Image.network('https://upfile.asqql.com/2009pasdfasdfic2009s305985-ts/2020-6/2020679131113978.gif');
        return Image.file(File(asset.filePath));
      }),
    );
  }

  Future<void> loadAssets() async {
    List<Asset> resultList = [];
    String error = 'No Error Dectected';
    try {
      // "29B30966-7BC9-481C-9AA4-BE0A675112D3/L0/001"
      // "A4FE7B79-7CF7-4E22-B55E-936A22CE22F7/L0/001"
      // "573E487B-9ABA-4BE0-B219-C2FF8C1B1B9E/L0/001"
      // "EC0BC104-AD12-46EB-B84A-3DA224099BBE/L0/001"
      // "7630B37C-CEBA-485A-8347-17B517AEA999/L0/001"
      // "4FC8A835-B8DD-4648-9E90-5C7F894DE9A1/L0/001"

      // final preSelectMedias = [
      //   '4D1A6122-2B8D-4B19-807E-9FDDB28748C2/L0/001',
      //   '9EF3E2D4-398D-4EAA-B1AB-404C278A8AC7/L0/001',
      //   'B983761E-101D-4CA6-AEE6-ED7149664B06/L0/001',
      //   '20E2BC98-4677-4D80-A699-0F34AFF5D134/L0/001'
      // ];
      // final preSelectMedia = 'B983761E-101D-4CA6-AEE6-ED7149664B06/L0/001';
      // final preSelectMedias = ["120818", "120817", "120816"];
      // final preSelectMedia = '1960634';

// '24E7EFE4-2D3A-4C27-A96C-0F1AC085AAB9/L0/001'
      final result = await MultiImagePicker.pickImages(
        maxImages: 9,
        defaultAsset: null,
        selectedAssets: null,
        doneButtonText: "下一步",
        thumbType: FBMediaThumbType.file,
        mediaShowType: FBMediaShowType.all,
        cupertinoOptions: CupertinoOptions(
            takePhotoIcon: "chat",
            selectionStrokeColor: "#ff6179f2",
            selectionFillColor: "#ff6179f2"),
        materialOptions: MaterialOptions(
            allViewTitle: "All Photos", selectCircleStrokeColor: "#ff6179f2"),
      );
      print(result);

      // final list = [
      //   "29B30966-7BC9-481C-9AA4-BE0A675112D3/L0/001",
      //   "A4FE7B79-7CF7-4E22-B55E-936A22CE22F7/L0/001",
      //   "573E487B-9ABA-4BE0-B219-C2FF8C1B1B9E/L0/001",
      //   "EC0BC104-AD12-46EB-B84A-3DA224099BBE/L0/001",
      //   "7630B37C-CEBA-485A-8347-17B517AEA999/L0/001",
      //   "4FC8A835-B8DD-4648-9E90-5C7F894DE9A1/L0/001"
      // ];

      // final preSelectMedias = [
      //   '2B9C5D27-2767-45FE-9C51-EE598DFA2730/L0/001',
      //   '270DD1E8-8DE5-4FEC-A3DA-E8B569D2FA8D/L0/001',
      //   'CDFD2F31-3AAF-4A95-85D9-AD14F746AD46/L0/001',
      //   '4EEE33AB-2C0A-4639-844A-C76FEE518D1A/L0/001',
      //   'BC0FC2EA-73B9-4800-A271-77A111DEC1EB/L0/001',
      //   '955B5A81-55F1-4F20-9A8F-DA4609727896/L0/001'
      // ];

      // print('123');

      // final fileSize = await MultiImagePicker.requestFileSize(
      //     'F9D725E8-BF01-4FF2-A61C-3EC033C181C1/L0/001');
      // if (double.parse(fileSize) > 1024 * 1024 * 8) {}
      // print(fileSize);
      // final List<String> identifers = [];
      // result['identifiers']
      //     .forEach((element) => identifers.add(element.toString()));
      // final result1 =
      //     await MultiImagePicker.requestFilePath(identifers[0].toString());
      // print("result1: $result1");

      final ids = (result['identifiers'] as List).cast<String>();
      print('请求压缩');
      MultiImagePicker.requestMediaData(
              thumb: true,
              selectedAssets: (result['identifiers'] as List).cast<String>())
          .then((xx) {
        xx.forEach((element) {
          print('压缩结果： ${element.name} ${element.thumbFilePath}');
        });
      });

      // final result = await MultiImagePicker.
      // for (var item in assets) {
      //   print(item.filePath);
      //   print(item.checkPath);
      // }

      // final dir = await MultiImagePicker.requestThumbDirectory();

      // String path = dir + "big_jpg.JPG";
      // final t1 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "image", fileList: [path]);
      // print(t1[0].toJsonMap());
      // path = dir + "gif.GIF";
      // final t2 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "image", fileList: [path]);
      // print(t2[0].toJsonMap());
      // path = dir + "heic.HEIC";
      // final t3 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "image", fileList: [path]);
      // print(t3[0].toJsonMap());
      // path = dir + "IMG_1582.GIF";
      // final t4 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "image", fileList: [path]);
      // print(t4[0].toJsonMap());
      // path = dir + "jpg.JPG";
      // final t5 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "image", fileList: [path]);
      // print(t5[0].toJsonMap());
      // path = dir + "mp4.mp4";
      // final t6 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "video", fileList: [path]);
      // print(t6[0].toJsonMap());
      // path = dir + "png.PNG";
      // final t7 = await MultiImagePicker.requestCompressMedia(true,
      //     fileType: "image", fileList: [path]);
      // print(t7[0].toJsonMap());

      // print(resultList);
      // print(resultList[0].toJsonMap());
      // print(resultList[1].toJsonMap());
      // print(resultList[2].toJsonMap());
      // print(resultList[3].toJsonMap());
      // print(resultList[4].toJsonMap());

      // await MultiImagePicker.fetchMediaInfo(50, 31);
      // MultiImagePicker.fetchMediaInfo(0, 10, selectedAssets: list)
      //     .then((value) {
      //   print(value);
      //   print('123');
      // });

      // for (var item in list) {
      //   print(await MultiImagePicker.requestFileDimen(item));
      // }

      // final result = await MultiImagePicker.requestFileDimen('2004950');
      // print(result);

      // Asset asset =
      //     await MultiImagePicker.requestTakePicture(themeColor: "#ff6179f2");
      // resultList.add(asset);
      // print(asset);

      // print(await MultiImagePicker.requestThumbDirectory());
      // for (var asset in assets) {
      //   print(asset.identifier);
      // }
      // print(assets);

      // final fileSize = await MultiImagePicker.requestFileSize(
      //     "334D2E75-7DFD-4D76-B8E3-BB2B5A84B533/L0/001");
      // if (double.parse(fileSize) > 1024 * 1024 * 8) {}
      // print(fileSize);

      // final data = await MultiImagePicker.fetchMediaThumbData(
      //     "02918F54-8DAE-461B-97F9-DA8E0FE124F5/L0/001", "video");
      // print(data);

      // Uint8List data1 = await MultiImagePicker.fetchMediaThumbData("53F55494-C4C0-4FB7-8365-8326BBC0693D/L0/001");
      // print(data);
    } on Exception catch (e) {
      print(e);
      error = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      _error = error;
    });
  }
}
