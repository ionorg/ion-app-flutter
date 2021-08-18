import 'package:flutter_ion/flutter_ion.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IonController extends GetxController {
  SharedPreferences? _prefs;
  late String _sid;
  late String _name;
  final String _uid = Uuid().v4();
  IonBaseConnector? _baseConnector;
  IonAppBiz? _biz;
  IonSDKSFU? _sfu;

  String get sid => _sid;

  String get uid => _uid;

  String get name => _name;

  IonAppBiz? get biz => _biz;

  IonSDKSFU? get sfu => _sfu;

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

  setup(host) {
    _baseConnector = new IonBaseConnector(host);
    _biz = new IonAppBiz(_baseConnector!);
    _sfu = new IonSDKSFU(_baseConnector!);
  }

  connect() async {
    await _biz!.connect();
    await _sfu!.connect();
  }

  joinBIZ(String roomID, String displayName) async {
    _biz!.join(sid: roomID, uid: _uid, info: {'name': '$displayName'});
  }

  joinSFU(String roomID, String displayName) async {
    _sfu!.join(roomID, displayName);
  }

  close() async {
    _biz?.leave(_uid);
    _biz?.close();
    _biz = null;
  }
}
