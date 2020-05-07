import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:multi_image_picker/src/asset.dart';

class AssetThumb extends StatefulWidget {
  /// The asset we want to show thumb for.
  final Asset asset;

  /// The thumb width
  final int width;

  /// The thumb height
  final int height;

  /// The thumb quality
  final int quality;

  /// This is the widget that will be displayed while the
  /// thumb is loading.
  final Widget spinner;

  const AssetThumb({
    Key key,
    @required this.asset,
    @required this.width,
    @required this.height,
    this.quality = 100,
    this.spinner = const Center(
      child: SizedBox(
        width: 50,
        height: 50,
        child: CircularProgressIndicator(),
      ),
    ),
  }) : super(key: key);

  @override
  _AssetThumbState createState() => _AssetThumbState();
}

class _AssetThumbState extends State<AssetThumb> {
  int get width => widget.width;
  int get height => widget.height;
  int get quality => widget.quality;
  Asset get asset => widget.asset;
  Widget get spinner => widget.spinner;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(AssetThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
 
  @override
  Widget build(BuildContext context) {
    if (widget.asset.filePath.isEmpty) {
      return spinner;
    }

    if (widget.asset.filePath.isNotEmpty) {
      return Image.file(
        File(widget.asset.filePath),
        key: ValueKey(asset.identifier),
        fit: BoxFit.cover,
        gaplessPlayback: true);
    }
  }
}
