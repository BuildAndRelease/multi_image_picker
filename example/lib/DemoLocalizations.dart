import 'package:flutter/material.dart';
class DemoLocalizations {

  final Locale locale;

  DemoLocalizations(this.locale);

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'pick image': 'pick image',
      'titlebar title': 'Muti Image Pick'
    },
    'zh': {
      'pick image': '选择图片',
      'titlebar title': '图片选择插件'
    }
  };

  get imagePick{
    return _localizedValues[locale.languageCode]['pick image'];
  }

  get titleBarTitle{
    return _localizedValues[locale.languageCode]['titlebar title'];
  }

  //此处
  static DemoLocalizations of(BuildContext context){
    return Localizations.of(context, DemoLocalizations);
  }
}