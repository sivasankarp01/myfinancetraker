import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myfinancetraker/firebase_options.dart';
import 'package:myfinancetraker/home.dart';

import 'package:myfinancetraker/signin.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox('itemsBox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myfinancetraker',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
      ),
      home: HomePage(),
    );
  }
}
