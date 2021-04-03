import 'package:flutter_ion/flutter_ion.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IonController extends GetxController {
  SharedPreferences? _prefs;
  IonConnector? _ion;
  late String _sid;
  late String _name;
  final String _uid = Uuid().v4();
  IonConnector? get ion => _ion;
  String get sid => _sid;
  String get uid => _uid;
  String get name => _name;
  Client? get sfu => _ion?.sfu;

  @override
  void onInit() async {
    super.onInit();
    print('IonController::onInit');
  }

  Future<SharedPreferences> prefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  connect(host) async {
    if (_ion == null) {
      var url = 'http://$host:5551';
      _ion = new IonConnector(url: url);
    }
  }

  join(String sid, String displayName) async {
    _sid = sid;
    _name = displayName;
    _ion?.join(sid: _sid, uid: _uid, info: {'name': '$displayName'});
  }

  close() async {
    _ion?.leave(_uid);
    _ion?.close();
    _ion = null;
  }
}
