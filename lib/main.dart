import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/high_score_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final highScore = await HighScoreStore.load();
  runApp(FruitNinjaApp(highScore: highScore));
}

class FruitNinjaApp extends StatelessWidget {
  const FruitNinjaApp({super.key, this.highScore = 0});

  final int highScore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Ninja TiahM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeScreen(highScore: highScore),
    );
  }
}
