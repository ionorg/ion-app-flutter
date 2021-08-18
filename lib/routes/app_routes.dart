part of 'app_pages.dart';

abstract class Routes {
  static const Home = 'Login';
  static const NotFound = '/not-found';
}

extension RoutesExtension on String {
  String nameToRoute() => '/${toLowerCase()}';
}
