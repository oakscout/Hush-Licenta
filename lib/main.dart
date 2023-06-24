import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'background_service.dart';
import 'utils.dart';
import 'Start_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundService.initialize();
  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  Isolate.spawn(BackgroundService.startService, rootIsolateToken);
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TextProvider(),
      child: MaterialApp(
        title: 'Your App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        //home: StartPage(),
        home: StartPage(),
        //home: SignInDemo(),
      ),
    );
  }
}
