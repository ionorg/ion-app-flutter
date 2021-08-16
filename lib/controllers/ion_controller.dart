import 'package:flutter_ion/flutter_ion.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IonController extends GetxController {
  SharedPreferences? _prefs;
  IonAppBiz? _ion;
  late String _sid;
  late String _name;
  final String _uid = Uuid().v4();
  Client? clientSFU;
  GRPCWebSignal? signal;

  IonAppBiz? get ion => _ion;

  String get sid => _sid;

  String get uid => _uid;

  String get name => _name;

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

  connectBIZ(host) async {
    if (_ion == null) {
      IonBaseConnector _baseConnector = IonBaseConnector(host);
      _ion = IonAppBiz(_baseConnector);
      await _ion!.connect();
    }
  }

  connectSFU(host) async {
    signal = GRPCWebSignal(host);
    clientSFU = await Client.create(sid: _sid, uid: _uid, signal: signal!);
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
