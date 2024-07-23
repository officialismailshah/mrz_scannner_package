import 'package:example/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:mrz_scanner/mrz_scanner.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final MRZController controller = MRZController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        return MRZScanner(
          controller: controller,
          onSuccess: (mrzResult, lines, img) async {
            String id = lines.first.substring(15, lines.first.length);
            Route route = MaterialPageRoute(builder: (context) {
              return DetailScreen(
                mrzResult: mrzResult,
                id: id,
                image: img,
              );
            });
            Navigator.of(context).push(route);
          },
        );
      }),
    );
  }
}
