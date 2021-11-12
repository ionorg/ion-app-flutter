import 'package:flutter_ion/flutter_ion.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IonController extends GetxController {
  SharedPreferences? _prefs;
  late String _sid;
  late String _name;
  final String _uid = Uuid().v4();
  Connector? _connector;
  Room? _room;
  RTC? _rtc;

  String get sid => _sid;

  String get uid => _uid;

  String get name => _name;

  Room? get room => _room;

  RTC? get rtc => _rtc;

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

  setup(
      {required String host,
      required String room,
      required String name}) async {
    print('IonController setup');
    _connector = new Connector(host);
    _room = new Room(_connector!);
    _rtc = new RTC(_connector!);
    _sid = room;
    _name = name;
    print('IonController setup ok');
  }

  connect() async {
    await _room!.connect();
    await _rtc!.connect();
    print('IonController connect()');
  }

  joinROOM() async {
    _room!.join(
        peer: Peer()
          ..sid = _sid
          ..uid = _uid
          ..displayname = _uid
          ..extrainfo = []
          ..destination = ''
          ..role = Role.HOST
          ..direction = Direction.BILATERAL
          ..protocol = Protocol.WEBRTC
          ..avatar = ''
          ..vendor = '');
    print('joinROOM ' + 'sid=' + sid + ' uid=' + uid);
  }

  joinRTC() async {
    _rtc!.join(_sid, _uid, JoinConfig());
  }

  close() async {
    _room?.leave(_uid);
    _room?.close();
    _room = null;
  }

  subscribe(List<Subscription> infos) {
    _rtc!.subscribe(infos);
  }
}
