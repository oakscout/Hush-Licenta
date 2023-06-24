import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextProvider extends ChangeNotifier {
  String? savedText;

  Future<void> updateText(String text) async {
    savedText = text;
    notifyListeners();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedText', text);
  }

  Future<void> loadSavedText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedText = prefs.getString('savedText');
    notifyListeners();
  }
}