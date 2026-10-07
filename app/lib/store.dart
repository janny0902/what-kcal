import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class MealStore extends ChangeNotifier {
  static const _mealsKey = 'whatkcal-meals';
  static const _helloKey = 'whatkcal-hello';
  static const _compareKey = 'whatkcal-compare';

  List<MealRecord> meals = [];
  bool helloSeen = false;
  String compare = '여성';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    helloSeen = prefs.getBool(_helloKey) ?? false;
    compare = prefs.getString(_compareKey) ?? '여성';
    final raw = prefs.getString(_mealsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List;
      meals = decoded.map((item) => MealRecord.fromJson(Map<String, dynamic>.from(item as Map))).toList();
      meals.sort((a, b) => (b.mealDate + b.mealTime).compareTo(a.mealDate + a.mealTime));
    }
  }

  Future<void> _write() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mealsKey, jsonEncode(meals.map((meal) => meal.toJson()).toList()));
    notifyListeners();
  }

  Future<void> markHello() async {
    helloSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_helloKey, true);
  }

  Future<void> setCompare(String value) async {
    compare = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_compareKey, value);
    notifyListeners();
  }

  Future<String> persistImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/meals');
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest = File('${folder.path}/${DateTime.now().microsecondsSinceEpoch}.jpg');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  Future<void> save(MealRecord meal) async {
    meal.updatedAt = DateTime.now().millisecondsSinceEpoch;
    meals.removeWhere((item) => item.id == meal.id);
    meals.add(meal);
    meals.sort((a, b) => (b.mealDate + b.mealTime).compareTo(a.mealDate + a.mealTime));
    await _write();
  }

  Future<void> delete(String id) async {
    final meal = meals.cast<MealRecord?>().firstWhere((item) => item?.id == id, orElse: () => null);
    if (meal != null && meal.imagePath.isNotEmpty) {
      final file = File(meal.imagePath);
      if (await file.exists()) await file.delete();
    }
    meals.removeWhere((item) => item.id == id);
    await _write();
  }

  Future<void> clear() async {
    for (final meal in meals) {
      if (meal.imagePath.isEmpty) continue;
      final file = File(meal.imagePath);
      if (await file.exists()) await file.delete();
    }
    meals = [];
    await _write();
  }
}
