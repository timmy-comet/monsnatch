import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monsnatch/presentation/blocs/user/user_bloc.dart';
import 'core/constants/app_colors.dart';
import 'injection_container.dart';
import 'presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ LOCK VERTICAL ONLY
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  initDependencies();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<UserBloc>()..loadUser()),
      ],
      child: const MonSnatchApp(),
    ),
  );
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