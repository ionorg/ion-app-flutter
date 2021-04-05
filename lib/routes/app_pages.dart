import 'package:get/get.dart';
import 'package:ion/pages/chat/chat_page.dart';
import '../pages/login/login_page.dart';
import '../pages/meeting/meeting_page.dart';
import '../pages/settings/settings_page.dart';
part 'app_routes.dart';

// ignore: avoid_classes_with_only_static_members
class AppPages {
  static String init = Routes.Home.nameToRoute();

  static final routes = [
    GetPage(
      name: '/login',
      title: 'Login View',
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: '/meeting',
      title: 'Meeting View',
      page: () => MeetingView(),
      binding: MeetingBinding(),
    ),
    GetPage(
      name: '/settings',
      title: 'Settings View',
      page: () => SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: '/chat',
      title: 'Chat View',
      page: () => ChatView(),
      binding: ChatBinding(),
    ),
  ];
}
