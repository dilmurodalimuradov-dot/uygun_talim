import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/providers/connection_status_provider.dart';
import 'core/providers/face_verification_provider.dart';
import 'core/providers/locale_provider.dart';
import 'shared/routes/app_router.dart';
import 'shared/theme/app_colors.dart';
import 'shared/widgets/connection_gate.dart';

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

  // Internet/server holatini kuzatuvchi global provider — ApiClient'dagi
  // har qanday tarmoq/server xatosi shu obyekt orqali butun ilovaga
  // signal beradi.
  final connectionStatus = ConnectionStatusProvider();

  await ServiceLocator.init(connectionStatus: connectionStatus);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FaceVerificationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: connectionStatus),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.primary);

    return MaterialApp(
      title: "Uyg'un Ta'lim",
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRouter.initialRoute,
      routes: AppRouter.routes,
      onUnknownRoute: AppRouter.onUnknownRoute,

      // --- Localization ---
      locale: locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Butun ilovani ConnectionGate bilan o'raymiz — internet yo'q yoki
      // serverda muammo bo'lsa, qaysi sahifada turilganidan qat'iy nazar
      // ustiga to'liq ekranli "Internet/Server xatosi" sahifasi chiqadi va
      // muammo tuzalmaguncha turadi. Tuzalganda avtomatik yo'qoladi va
      // foydalanuvchi to'xtagan joyidan davom etadi.
      builder: (context, child) {
        return ConnectionGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
