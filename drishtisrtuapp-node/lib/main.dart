import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/sentinel_node_screen.dart';

List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  try {
    _cameras = await availableCameras();
  } catch (_) {
    _cameras = [];
  }

  runApp(const DrishtiSetuNodeApp());
}

class DrishtiSetuNodeApp extends StatelessWidget {
  const DrishtiSetuNodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrishtiSetu Node',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: SentinelNodeScreen(cameras: _cameras),
    );
  }
}
