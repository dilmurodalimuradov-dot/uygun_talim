import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/providers/face_verification_provider.dart';
import 'shared/routes/app_router.dart';
import 'shared/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.primary,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  await ServiceLocator.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FaceVerificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
    return MaterialApp(
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRouter.initialRoute,
      routes: AppRouter.routes,
      onUnknownRoute: AppRouter.onUnknownRoute,
    );
  }
}
