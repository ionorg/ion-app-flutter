import 'package:events2/events2.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:uuid/uuid.dart';

class IonHelper extends EventEmitter {
  IonConnector _ion;
  String _sid;
  final String _uid = Uuid().v4();

  IonConnector get ion => _ion;

  String get sid => _sid;

  String get uid => _uid;

  Client get sfu => _ion.sfu;

  connect(host) async {
    if (_ion == null) {
      var url = 'http://$host:5551';
      _ion = new IonConnector(url: url);
    }

    _ion.onJoin = (bool success, String reason) {
      emit('handle-join', success, reason);
    };

    _ion.onLeave = (String reason) {
      emit('handle-leave', reason);
    };
  }

  join(String sid, String displayName) async {
    _sid = sid;
    _ion.join(sid: _sid, uid: _uid, info: {'name': '$displayName'});
  }

  close() async {
    if (_ion != null) {
      _ion.leave(_uid);
      _ion.close();
    }
  }
}
