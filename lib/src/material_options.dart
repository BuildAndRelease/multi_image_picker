class MaterialOptions {
  final String actionBarColor;
  final String statusBarColor;
  final bool lightStatusBar;
  final String actionBarTitleColor;
  final String allViewTitle;
  final String actionBarTitle;
  final bool startInAllView;
  final bool useDetailsView;
  final String selectCircleStrokeColor;
  final String selectionLimitReachedText;
  final String textOnNothingSelected;
  final String backButtonDrawable;
  final String okButtonDrawable;
  final bool autoCloseOnSelectionLimit;

  const MaterialOptions({
    this.actionBarColor = "",
    this.actionBarTitle = "",
    this.lightStatusBar = false,
    this.statusBarColor = "",
    this.actionBarTitleColor = "",
    this.allViewTitle = "",
    this.startInAllView = false,
    this.useDetailsView = false,
    this.selectCircleStrokeColor = "",
    this.selectionLimitReachedText = "",
    this.textOnNothingSelected = "",
    this.backButtonDrawable = "",
    this.okButtonDrawable = "",
    this.autoCloseOnSelectionLimit = false,
  });

  Map<String, String> toJson() {
    return {
      "actionBarColor": actionBarColor,
      "actionBarTitle": actionBarTitle,
      "actionBarTitleColor": actionBarTitleColor,
      "allViewTitle": allViewTitle,
      "lightStatusBar": lightStatusBar ? "true" : "false",
      "statusBarColor": statusBarColor,
      "startInAllView": startInAllView ? "true" : "false",
      "useDetailsView": useDetailsView ? "true" : "false",
      "selectCircleStrokeColor": selectCircleStrokeColor,
      "selectionLimitReachedText": selectionLimitReachedText,
      "textOnNothingSelected": textOnNothingSelected,
      "backButtonDrawable": backButtonDrawable,
      "okButtonDrawable": okButtonDrawable,
      "autoCloseOnSelectionLimit": autoCloseOnSelectionLimit ? "true" : "false"
    };
  }
}
