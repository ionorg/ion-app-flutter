import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/ion_controller.dart';
import './utils/utils.dart';
import './routes/app_pages.dart';
import 'pages/not_found/not_found_view.dart';
import './utils/logger_utils.dart';

void main() {
  Get.put(IonController(), permanent: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: true,
      unknownRoute: GetPage(name: '/not-found', page: () => NotFound()),
      enableLog: true,
      theme: mDefaultTheme,
      logWriterCallback: Logger.write,
      initialRoute: AppPages.init,
      getPages: AppPages.routes,
    );
  }
}

final ThemeData mDefaultTheme = ThemeData(
  primaryColor: string2Color('#0a0a0a'),
);
