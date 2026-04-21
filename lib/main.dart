import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'injection_container.dart';
import 'presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  initDependencies();
  runApp(const MonSnatchApp());
}

class MonSnatchApp extends StatelessWidget {
  const MonSnatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'MonSnatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed:  AppColors.createRoomBtn,
        useMaterial3:     true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        fontFamily:       'Nunito',    // add via pubspec if desired
      ),
      home: const HomePage(),
    );
  }
}