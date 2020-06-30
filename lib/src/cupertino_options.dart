class CupertinoOptions {
  final String selectionStrokeColor;
  final String selectionFillColor;
  final String selectionTextColor;
  final String selectionCharacter;
  final String takePhotoIcon;

  const CupertinoOptions({
    this.selectionFillColor,
    this.selectionStrokeColor,
    this.selectionTextColor,
    this.selectionCharacter,
    this.takePhotoIcon,
  });

  Map<String, String> toJson() {
    return {
      "selectionFillColor": selectionFillColor ?? "",
      "selectionStrokeColor": selectionStrokeColor ?? "",
      "selectionTextColor": selectionTextColor ?? "",
      "selectionCharacter": selectionCharacter ?? "",
      "takePhotoIcon": takePhotoIcon ?? ""
    };
  }
}
