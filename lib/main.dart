import 'package:chaerok/app/app.dart';
import 'package:chaerok/app/app_startup.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStartup.initialize();
  runApp(const ChaerokApp());
}
