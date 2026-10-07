import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads.dart';
import 'shell.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (adsSupported) {
    await MobileAds.instance.initialize();
  }
  final store = MealStore();
  await store.load();
  runApp(WhatKcalApp(store: store));
}
